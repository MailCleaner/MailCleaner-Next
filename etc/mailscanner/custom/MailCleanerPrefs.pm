package MailScanner::CustomConfig;

use strict 'vars';
use strict 'refs';
no  strict 'subs'; # Allow bare words for parameter %'s

use vars qw($VERSION);

$VERSION = substr q$Revision: 1.5 $, 10;

my($dbh);
my($sth);
my %config = readConfig("/etc/mailcleaner.conf");
my $srcdir = $config{'SRCDIR'};
if ($srcdir =~ /(\S+)/) {
  unshift (@INC, $1."/lib");
}
require Email;
require Domain;
require SystemPref;

##################
### SpamWall
##################
sub InitSpamWall {}
sub EndSpamWall {}
sub SpamWall {
	my($message) = @_;
	return unless $message;
	my $ret = getValue('spamwall', $message->{todomain}[0], 1);
	return $ret;
}

####################
##### VirusWall
####################
sub InitVirusWall {}
sub EndVirusWall {}
sub VirusWall {
        my($message) = @_;
        return unless $message;
	my $ret = getValue('viruswall', $message->{todomain}[0], 1);
        return $ret;
}

####################
##### AllowForms
####################
sub InitAllowForms {}
sub EndAllowForms {}
sub AllowForms {
	my($message) = @_;
        return unless $message;
        my $ret = getValue('allow_forms', $message->{todomain}[0], 0);
	return yesNoDisarmValue($ret);
}

####################
##### AllowScripts
####################
sub InitAllowScripts {}
sub EndAllowScripts {}
sub AllowScripts {
        my($message) = @_;
        return unless $message;
        my $ret = getValue('allow_scripts', $message->{todomain}[0], 0);
        return $ret;
}

####################
##### VirusSubject
####################
sub InitVirusSubject {}
sub EndVirusSubject {}
sub VirusSubject {
        my($message) = @_;
        return unless $message;
        my $ret = getValue('virus_subject', $message->{todomain}[0], '{Virus?}');
        return $ret;
}

####################
##### ContentSubject
####################
sub InitContentSubject {}
sub EndContentSubject {}
sub ContentSubject {
        my($message) = @_;
        return unless $message;
        my $ret = getValue('content_subject', $message->{todomain}[0], '{Content?}');
        return $ret;
}

##########################
##### StoredContentReport
##########################
sub InitStoredContentReport {}
sub EndStoredContentReport {}
sub StoredContentReport {
        my($message) = @_;
        return unless $message;
	my $lang = getValue('language', $message->{to}[0], 'en');
        my $ret = getValue('report_template', $message->{todomain}[0], 'default');
	my $res = $srcdir."/templates/reports/".$ret."/".$lang."/stored.content.message.txt";
        return $res;
}

##########################
##### StoredFilenameReport
##########################
sub InitStoredFilenameReport {}
sub EndStoredFilenameReport {}
sub StoredFilenameReport {
        my($message) = @_;
        return unless $message;
	my $lang = getValue('language', $message->{to}[0], 'en');
        my $ret = getValue('report_template', $message->{todomain}[0], 'default');
	my $res = $srcdir."/templates/reports/".$ret."/".$lang."/stored.filename.message.txt";
        return $res;
}

##########################
##### StoredVirusReport
##########################
sub InitStoredVirusReport {}
sub EndStoredVirusReport {}
sub StoredVirusReport {
        my($message) = @_;
        return unless $message;
	my $lang = getValue('language', $message->{to}[0], 'en');
        my $ret = getValue('report_template', $message->{todomain}[0], 'default');
	my $res = $srcdir."/templates/reports/".$ret."/".$lang."/stored.virus.message.txt";
        return $res;
}

##########################
##### LocalPostmaster
##########################
sub InitLocalPostmaster {}
sub EndLocalPostmaster {}
sub LocalPostmaster {
        my($message) = @_;
        return unless $message;
        my $postmaster = getValue('supportemail', $message->{todomain}[0], '');
        if ($postmaster eq '' || $postmaster eq 'NOTFOUND') {
            $postmaster = getValue('support_email', $message->{todomain}[0], '');
        }
        if ($postmaster eq '' || $postmaster eq 'NOTFOUND') {
          my $sysconf = SystemPref::create();
          if ( $sysconf) {
            $postmaster = $sysconf->getPref('sysadmin', '');
          } 
          if ($postmaster eq '') { 
            $postmaster = getValue('summary_from', '', '');
          }
        }
        return $postmaster;
}

##########################################
sub getValue {
	my $pref = shift;
	my $to = shift;
	my $default = shift;
	my $ref;
	my $res = $default;
	my $query = "";

        my $value = $default;
        if ($to =~ /\S+\@\S+/) {
          # user
          my $email = Email::create($to);
          if (! $email) { 
            MailScanner::Log::InfoLog("Couldn't create user: $to");
            return $default;
          }
          $value = $email->getPref($pref, $default);
        } elsif ($to =~ /\S+/) {
          # domain
          my $domain = Domain::create($to);
          if (! $domain) {
            MailScanner::Log::InfoLog("Couldn't create domain: $to");
            return $default;
          }
          $value = $domain->getPref($pref, $default);
        } else {
          # system
          my $sysconf = SystemPref::create();
          if (! $sysconf) {
            MailScanner::Log::InfoLog("Couldn't create system config");
            return $default;
          }
          $value = $sysconf->getPref($pref, $default);
        }
        #MailScanner::Log::InfoLog("Fetched pref: $pref, for $to => $value");
	return $value;
}

##########################################
sub yesNoDisarmValue {
	my $value = shift;

	if ($value == 2) {
		return 'convert';
	}
	return $value;
}

##########################################
sub readConfig {
        my $configfile = shift;
        my %config;
        my ($var, $value);

        open CONFIG, $configfile or die "Cannot open $configfile: $!\n";
        while (<CONFIG>) {
                chomp;                  # no newline
                s/#.*//;                # no comments
                s/;.*//;                # no comments
                s/^\s+//;               # no leading white
                s/\s+$//;               # no trailing white
                next unless length;     # anything left?
                my ($var, $value) = split(/\s*=\s*/, $_, 2);
                $config{$var} = $value;
        }
        close CONFIG;
        return %config;
}
1;
