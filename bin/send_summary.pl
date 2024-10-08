#!/usr/bin/env perl
#
#   Mailcleaner - SMTP Antivirus/Antispam Gateway
#   Copyright (C) 2004-2014 Olivier Diserens <olivier@diserens.ch>
#   Copyright (C) 2015-2017 Florian Billebault <florian.billebault@gmail.com>
#   Copyright (C) 2023 John Mertz <git@john.me.tz>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
#   This script will send the spam summaries to the users
#
#   Usage:
#           send_summary.pl [-a|email@address|domain.tld] mode nb_days
#   -a: sends to all users
#   email@address: sends to a given mail address
#   domain.tld: sends to all users of the domain domain.tld
#
#   mode is:
#           0 = requested by command line
#           1 = called by monthly script
#           2 = called by weekly script
#           3 = called by daily script
#   nb_days is the number of days contained in the summary

use v5.36;
use strict;
use warnings;
use utf8;
use Carp qw( confess );

my ($SRCDIR);
BEGIN {
    if ($0 =~ m/(\S*)\/\S+.pl$/) {
        my $path = $1."/../lib";
        unshift (@INC, $path);
    }
    require ReadConfig;
    my $conf = ReadConfig::getInstance();
    $SRCDIR = $conf->getOption('SRCDIR') || '/usr/mailcleaner';
    unshift(@INC, $SRCDIR."/lib");
}

if ($0 =~ m/(\S*)\/\S+.pl$/) {
    my $path = $1."/../lib";
    unshift (@INC, $path);
}

require DB;
require Email;
require MailTemplate;
use lib_utils qw ( create_lockfile remove_lockfile );

use Date::Calc qw(Add_Delta_Days Today Date_to_Text Date_to_Text_Long);
use DateTime;
use Encode;
use MIME::QuotedPrint;
use Digest::SHA1 qw(sha1_hex);

if ($conf->getOption('ISMASTER') !~ /^[y|Y]$/) {
    print "NOTAMASTER";
    exit 0;
}

## get params
my $address = shift;
my $mode = shift;
if ($mode < 0 || $mode >3) {
    print "INCORRECTPARAMS";
    exit 0;
}

my $days = shift;
if ($days !~ /^\d+$/) {
    print "INCORRECTPARAMS";
    exit 0;
}
# check for lock
my $lockfile_name = 'send_summary_' . $days . 'd';
my $rc = create_lockfile($lockfile_name, undef, time+10*60*60, 'send_summary');
if ($rc == 0) {
    print "CANNOTLOCK $lockfile_name\n";
    exit;
}

my $nodigest = 0;
if (scalar(@ARGV) && $ARGV[0] =~ /^nodigest$/) {
    $nodigest = 1;
}
## now we have coherent params.

## get some system prefs
my $sysconf = SystemPref::getInstance();
my $spamnbdays = $sysconf->getPref('days_to_keep_spams');

my $db = DB::connect('master', 'mc_spool', 0);
my $conf_db = DB::connect('master', 'mc_config', 0);
## and do the job, either for one or all addresses
my @addresses = getAllAddresses($address);

## delete expired digests
my $query = "DELETE FROM digest_access WHERE DATEDIFF(date_expire, NOW()) < 0;";
$conf_db->execute($query);

## loop through addresses
foreach my $a (@addresses) {
## @todo:
##    check if address is filtered.. but this may be tricky..

    #print "doing address: $a\n";
    my $email = Email::create($a);
    if (!$email) {
        #print "bad address: $a\n";
        next;
    }
    if ($email->getUserPref('gui_group_quarantines')) {
        $a = $email->getUser()->getMainAddress();
        $email = Email::create($email->getUser()->getMainAddress());
    }
    ## check preference against mode
    if ($mode > 0) {
        next if ($mode==1 && !$email->getPref('monthly_summary'));
        next if ($mode==2 && !$email->getPref('weekly_summary'));
        next if ($mode==3 && !$email->getPref('daily_summary'));
    }
    my $domain = $email->getDomainObject();
    my $type = $email->getPref('summary_type');
    my $lang = $email->getPref('language');
    my $temp_id = $domain->getPref('summary_template');
    if (! -d $conf->getOption('SRCDIR')."/templates/summary/".$temp_id) {
        $temp_id = 'default';
    }
    # In case of missing translation for summaries
    if (!defined($lang) || $lang eq '' || ! -d $conf->getOption('SRCDIR')."/templates/summary/".$temp_id."/$lang") {
        $lang = 'en';
    }
    my $to = $email->getPref('summary_to');
    my $template;
    if ($type eq 'digest' && $nodigest) {
        $type = 'html';
    }
    if ($type eq 'digest') {
        $template = MailTemplate::create('summary', 'digest', $temp_id, \$email, $lang, 'html');
    } else {
        $template = MailTemplate::create('summary', 'summary', $temp_id, \$email, $lang, $type);
    }

    my ($end_year, $end_month,$end_day) = Today();
    my ($start_year,$start_month,$start_day)  = Add_Delta_Days($end_year, $end_month,$end_day, 0-$days);

    my @spams;
    getFullQuarantine($a, \@spams, $email);

    my $textquarantine = getQuarantineTemplate($template, $template->getSubTemplate('LIST'), \@spams, 'text', $lang, $temp_id);
    my $htmlquarantine = getQuarantineTemplate($template, $template->getSubTemplate('HTMLQUARANTINE'), \@spams, 'html', $lang, $temp_id);

    my $end = DateTime->new('year' => $end_year, 'month' => $end_month, 'day' => $end_day );
    $end->set_locale($lang);
    my $start = DateTime->new('year' => $start_year, 'month' => $start_month, 'day' => $start_day );
    $start->set_locale($lang);
    my @addresses = ($a);
    if ($email->getUserPref('gui_group_quarantines')) {
        @addresses = $email->getLinkedAddresses();
    }
    my %replace = (
        '__NBDAYS__' => $days,
        '__SPAMNBDAYS__' => $spamnbdays,
        '__SUMSIGNATURE__' => 'MailCleaner',
        '\?\?END_LIST' => $textquarantine,
        '__HTMLQUARANTINE__' => $htmlquarantine,
        '__TEXTQUARANTINE__' => $textquarantine,
        '__NBSPAMS__' => scalar @spams,
        '__START_DAY__' => sprintf('%.2u', $start_day),
        '__START_MONTH__' => sprintf('%.2u', $start_month),
        '__START_YEAR__' => $start_year,
        '__START_SYEAR__' => sprintf('%.2u', $start_year-2000),
        '__END_DAY__' => sprintf('%.2u', $end_day),
        '__END_MONTH__' => sprintf('%.2u', $end_month),
        '__END_YEAR__' => $end_year,
        '__END_SYEAR__' => sprintf('%.2u', $end_year-2000),
        '__START_DATE__' => Encode::encode('UTF-8', $start->strftime("%x")),
        '__END_DATE__' => Encode::encode('UTF-8', $end->strftime("%x")),
        '__ADDRESSES__' => join(', ', @addresses)
    );

    #if ($type eq 'digest') {
    ## create new digest and save it
    my $firstspam = $spams[0];
    my $str = $firstspam->{exim_id}.'-'.$firstspam->{time_in}.'-'.@spams.'-'.time().$a;
    $str =~ s/:/-/g;
    my $hash = sha1_hex($str);
    $replace{'__DIGEST_ID__'} = 'NOTGENERATED';
    if (!defined($spamnbdays) || $spamnbdays eq '') {
        $spamnbdays = 1;
    }
    my $clean_a = $a;
    $clean_a =~ s/'/''/g;
    my $query = "INSERT INTO digest_access VALUES('$hash', DATE(NOW()), DATE_SUB(NOW(), INTERVAL $days DAY), DATE(DATE_ADD(NOW(), INTERVAL $spamnbdays DAY)), '$clean_a');";

    if ($conf_db->execute($query)) {
        $replace{'__DIGEST_ID__'} = $hash;
    } else {
        my $query = "SELECT address FROM digest_access WHERE id = '$hash';";
        my $old = ($conf_db->getListOfHash($query))[0]->{address};
        if ($old eq $a) {
        my $query = "UPDATE digest_access SET date_in = DATE(NOW()), date_start = DATE_SUB(NOW(), INTERVAL $days DAY), date_expire = DATE(DATE_ADD(NOW(), INTERVAL $spamnbdays DAY)) WHERE id = '$hash';";
        if ($conf_db->execute($query)){
            $replace{'__DIGEST_ID__'} = $hash;
        } else {
            print 'COULDNOTUPDATEEXPIRY '.$query."\n";
        }
        } else {
        print 'COULDNOTUPDATEEXPIRY for different address '.$clean_a.' '.$query."\n";
        }
    }
    $template->setReplacements(\%replace);
    my $result = $template->send($to, 10);
    if ($result) {
        my $date = `date '+%Y-%m-%d %H:%M:%S'`;
        chomp($date);
        my $nbspams = scalar @spams;
        if ($email->getUserPref('gui_group_quarantines')) {
            $a = join(',', $email->getLinkedAddresses());
        }
        if (!$to) {
            $to = $email->getUser()->getMainAddress();
        }
        print "$date SUMSENT to $to for $a (days: $days, spams: $nbspams, id: $result)\n";
    }
}

remove_lockfile($lockfile_name);

###
# get all addresses to send summary
# @return    array   list of addresses
###
sub getAllAddresses
{
    my ($domain) = @_;

    # if we had an address and not a domain no need to look for other addresses
    return ($domain) if ($domain =~ /\S+\@\S+$/);

    my @list;
    my %addnottoadd;

    foreach my $letter ('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','misc', 'num') {
        if ($db && $db->ping()) {
            my $query = "SELECT to_user, to_domain FROM spam_$letter WHERE ";
            # We were asked about a specific domain
            if ($domain ne '-a') {
                $domain =~ s/^@//;
                $query .= "to_domain='$domain' AND ";
            } else {
                $query .= "to_user NOT LIKE '\%+\%' AND "
            }
            $query .= "TO_DAYS(NOW())-TO_DAYS(date_in) < $days+1 GROUP BY to_user, to_domain";
            my @res = $db->getListOfHash($query);
            foreach my $a_h (@res) {
                my $a = $a_h->{'to_user'}."@".$a_h->{'to_domain'};
                if ($addnottoadd{$a}) {
                    next;
                }
                my $email = Email::create($a);
                if ($email->getUserPref('gui_group_quarantines')) {
                    foreach my $nottoadd ($email->getLinkedAddresses()) {
                        $addnottoadd{$nottoadd} = 1;
                    }
                }
                push @list, $a;
            }
        }
    }
    return @list;
}

###
# fetch the full spam quarantine
# @param  $address   string        email address
# @param  $spams     array handle  handle of spams array
# @return            boolean       true on success, false on failure
###
sub getFullQuarantine($address,$spams_h,$email)
{
    my ($to_local, $to_domain, $initial);

    if ($address =~ /(\S+)@(\S+)/) {
        $to_local = $1;
        $to_domain = $2;
        $initial = substr($to_local, 0, 1);
    } else {
        return 0;
    }
    my $table = "spam_misc";
    if ($to_local =~ /^([a-z,A-Z])/) {
        $table = 'spam_'.lc($1);
    } elsif ($to_local =~ /^[0-9]/) {
        $table = 'spam_num';
    } else {
        $table = 'spam_misc';
    }

    my $addwhere = "to_domain='$to_domain' AND (to_user='$to_local' OR to_user LIKE '$to_local+%')";
    if ($email) {
        if ($email->getUserPref('gui_group_quarantines')) {
            $table = 'spam';
            $addwhere = "";
            foreach my $add ($email->getLinkedAddresses()) {
                if ($add =~ m/(\S+)\@(\S+)/) {
                    $addwhere .= " OR (to_domain='$2' AND (to_user='$1' OR to_user LIKE '$1+%'))";
                }
            }
            $addwhere =~ s/^\ OR\ //;
        }
    }

    my $query = "SELECT exim_id, sender, to_domain, to_user, time_in, HOUR(time_in) as T_h, MINUTE(time_in) as T_m, SECOND(time_in) as T_s, YEAR(date_in) as M_y, MONTH(date_in) as M_m, DAYOFMONTH(date_in) as M_d, M_subject, store_slave, M_score, M_prefilter, M_globalscore, is_newsletter FROM $table  WHERE ($addwhere) AND TO_DAYS(NOW())-TO_DAYS(date_in) < $days+1 GROUP BY exim_id ORDER BY date_in DESC, time_in DESC";
    if ($db && $db->ping()) {
        @{$spams_h} = $db->getListOfHash($query);
    }
}

# fill the quarantine template with datas and return string
# @param  $template  MailTemplate  template object
# @param  $tmpl      string        quarantine list template
# @param  $spams     array handle  handle of spams array
# @param  $type      string        test or html
# @return            string        filled quarantine template
###
sub getQuarantineTemplate($template,$tmpl,$spams,$type,$lang,$temp_id)
{
    my $ret = "";
    my $i = 0;
    my $bullet_filled = $template->getDefaultValue('FILLEDBULLET');
    my $bullet_empty = $template->getDefaultValue('EMPTYBULLET');

    use URI::Escape;

    my %lang_news = (
        'de' => 'Newsletter',
        'en' => 'Newsletter',
        'es' => 'Boletin Informativo',
        'fr' => 'Newsletter',
        'it' => 'Newsletter',
        'nb_NO' => 'Nyhetsbrev',
        'nl' => 'Nieuwsbrief',
        'pl' => 'Biuletyn'
    );

    my %lang_spam = (
        'de' => 'Spam',
        'en' => 'Spam',
        'es' => 'Spam',
        'fr' => 'Spam',
        'it' => 'Spam',
        'nb_NO' => 'Spam',
        'nl' => 'Spam',
        'pl' => 'Spamu'
    );

    my $spamblock = '';
    my $newsblock = '';
    foreach my $item (@{$spams}) {
        my $tmp = $tmpl;
        if ($type eq 'html') {
            use HTML::Entities;
            foreach my $key (keys %{$item}) {
                $item->{$key} = encode_entities($item->{$key});
            }
        } else {
            if ($item->{'is_newsletter'} > 0) {
                $tmp =~ s/((\_\_|\?\?)ID(\_\_)?)/$1 ($lang_news{$lang})/;
            }
        }

        my $gscore = "";
        my $score = $item->{'M_globalscore'};
        for (my $i=1; $i < 5; $i++) {
            if ($score >= $i) {
                $gscore .= $bullet_filled;
            } else {
                $gscore .= $bullet_empty;
            }
        }
        if ($score > 4 || $score < 0) {
            $score = 4;
        }
        my $pictoscore = $template->getDefaultValue("SCORE".$score);

        my $s_local = "";
        my $s_domain = "";
        if ($item->{'sender'} =~ /^(\S+)\@(\S+)$/) {
            $s_local = $1;
            $s_domain = $2;
            if ($type eq 'html') {
                my $totallen = 50;
                unless (length($s_local) + length($s_domain) < $totallen) {
                    if (length($s_local) > $totallen/2 && length($s_domain) > $totallen/2) {
                        $s_local = substr($s_local, 0, $totallen/2);
                        $s_domain = substr($s_domain, 0, $totallen/2);
                    } elsif (length($s_local) > $totallen/2) {
                        if (length($s_local) > $totallen-length($s_domain)) {
                            $s_local = substr($s_local, 0, $totallen-length($s_domain))."...";
                        }
                    } elsif (length($s_domain) > $totallen-length($s_local)) {
                        $s_domain = substr($s_domain, 0, $totallen-length($s_local))."...";
                    }
                }
            }
        }

        my $text_from = $item->{'sender'};
        my $s_subject = $item->{'M_subject'};
        my $text_subject = $item->{'M_subject'};

        my $decoded = eval { decode("MIME-Header", $s_subject); };
        if ($decoded) {
            $decoded =~ s/^(.{100}).*$/$1.../;
            my $encoded = encode("utf8", $decoded);
            $text_subject = $decoded;
            $decoded =~ s/^(.{50}).*$/$1.../;
            $encoded = encode("utf8", $decoded);
            $s_subject = $encoded;
        } else {
            $s_subject =~ s/^(.{50}).*$/$1.../;
        }

        my $tmpfrom = '';
        if ($s_local ne '' && $s_domain ne '') {
            $tmpfrom = $s_local.'@'.$s_domain;
        }
        $tmp =~ s/(\_\_|\?\?)NEWSLETTER(_TXT)?(\_\_)?//g;
        $tmp =~ s/(\_\_|\?\?)FROM(\_\_)?/$tmpfrom/g;
        $tmp =~ s/(\_\_|\?\?)TEXTFROM(\_\_)?/$text_from/g;
        $tmp =~ s/(\_\_|\?\?)ID(\_\_)?/$item->{exim_id}/g;
        $tmp =~ s/(\_\_|\?\?)SUBJECT(\_\_)?/$s_subject/g;
        $tmp =~ s/(\_\_|\?\?)TEXTSUBJECT(\_\_)?/$text_subject/g;

        my $itemdate = DateTime->new(
        'year' => $item->{'M_y'}, 'month' => $item->{'M_m'}, 'day' => $item->{'M_d'},
        'hour' => $item->{'T_h'}, 'minute' =>  $item->{'T_m'}, 'second' =>  $item->{'T_s'}
        );
        $itemdate->set_locale($lang);
        my $strdate = Encode::encode('UTF-8', $itemdate->strftime("%c"));

        $tmp =~ s/\_\_SINGLEDATE\_\_/$item->{'M_d'}-$item->{'M_m'}-$item->{'M_y'}/g;
        $tmp =~ s/\_\_SINGLETIME\_\_/$item->{'time_in'}/g;
        $tmp =~ s/\_\_SINGLEDATETIME\_\_/$strdate/g;
        $item->{'to_user'} =~ s/&#39;/'/;
        my $tmprcpt = uri_escape($item->{'to_user'}.'@'.$item->{'to_domain'});
        if ($item->{'is_newsletter'} > 0) {
            $tmprcpt .= '&n=1';
        }
        $tmp =~ s/(\_\_|\?\?)RECIPIENT(\_\_)?/$tmprcpt/g;
        $tmp =~ s/(\_\_|\?\?)ADDRESS(\_\_)?/$tmprcpt/g;
        $tmp =~ s/\_\_SCORE\_\_/$gscore/g;
        $tmp =~ s/\_\_SCOREPICTO\_\_/$pictoscore/g;
        $tmp =~ s/(\_\_|\?\?)STOREID(\_\_)?/$item->{'store_slave'}/g;
        $tmp =~ s/(\_\_|\?\?)DATE(\_\_)?/$item->{'M_d'}-$item->{'M_m'}-$item->{'M_y'} $item->{'time_in'}/g;
        if ($i++ % 2) {
            $tmp =~ s/__ALTCOLOR__(\S{7})/$1/g;
        } else {
            $tmp =~ s/\ bgcolor=\"__ALTCOLOR__\S{7}\"//g;
        }
        if ($item->{'is_newsletter'} > 0 && $type eq 'html') {
            $newsblock .= $tmp;
        } else {
            $spamblock .= $tmp;
        }
    }

    if ($type eq 'html') {
        if ($newsblock) {
            $ret .= '<tr id="news"><th colspan="5" style="border-left: solid 1px #CCC1C9;"><div class="qt"><b>' . ( (defined($lang_news{$lang})) ? $lang_news{$lang} : 'Newsletters' ) . '</b></div></th></tr>';
            $ret .= $newsblock;
        }
        if ($spamblock) {
            $ret .= '<tr id="spam"><th colspan="5" style="border-left: solid 1px #CCC1C9;"><div class="qt"><b>' . ( (defined($lang_spam{$lang})) ? $lang_spam{$lang} : 'Spam' ) . '</b></div></th></tr>';
            $ret .= $spamblock;
        }
    } else {
        $ret .= $spamblock;
    }
    return $ret;

}
