#!/usr/bin/env perl
#
#   Mailcleaner - SMTP Antivirus/Antispam Gateway
#   Copyright (C) 2004 Olivier Diserens <olivier@diserens.ch>
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
#   This script will dump the apache config file with the configuration
#   settings found in the database.
#
#   Usage:
#           spec_stats.sh nb_days [mode]
#   where nb_days is the number of days until today to fetch stats
#   and mode is one of the following:
#        o = output only the stats of the selected day (today - nb_days)
#        g = output overall stats since selected day (today - nb_days)
#        d = output stats for every days until now

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

require DB;

my $last_days = shift;
if (!$last_days || $last_days !~ /^\d+$/) {
    printf("Usage: get_days_stats nb_days [mode]\n");
    printf(" where mode is: o = one day stats, g = overall stats until now, d = daily stats until now\n");
    exit 1;
}

my $until_now = 0;
$until_now = shift;
if (!$until_now || $until_now=~ /^$/) {
    $until_now = "o";
}
if (!$until_now || $until_now !~ /^o|g|d$/) {
    printf("Usage: get_days_stats nb_days [mode]\n");
    printf(" where mode is: o = one day stats, g = overall stats until now, d = daily stats until now\n");
    exit 1;
}

my $dbh;
$dbh = DB::connect('slave','mc_stats');

if ($until_now =~ /^d$/) {
    for (my $i=$last_days; $i>=0; $i--) {
        get_stats($i, 0);
    }
} elsif ($until_now =~ /^g$/) {
    get_stats($last_days, 1);
} else {
    get_stats($last_days, 0);
}

$dbh->disconnect();

sub get_stats($days,$mode)
{
    my %sql;
    my %val;
    my $date;
    if ($mode == 1) {
        $sql{1} = "SELECT DATE_FORMAT(DATE_SUB(NOW(), INTERVAL $days DAY), '%e %M %Y') d, COUNT(*) c FROM maillog WHERE date > DATE_SUB(NOW(), INTERVAL $days+1 DAY)";
        $sql{2} = "SELECT DATE_FORMAT(DATE_SUB(NOW(), INTERVAL $days DAY), '%e %M %Y') d, COUNT(*) c FROM maillog WHERE date > DATE_SUB(NOW(), INTERVAL $days+1 DAY) AND isspam=1";
        $sql{3} = "SELECT DATE_FORMAT(DATE_SUB(NOW(), INTERVAL $days DAY), '%e %M %Y') d, COUNT(*) c FROM maillog WHERE date > DATE_SUB(NOW(), INTERVAL $days+1 DAY) AND virusinfected=1";
        $sql{4} = "SELECT DATE_FORMAT(DATE_SUB(NOW(), INTERVAL $days DAY), '%e %M %Y') d, COUNT(*) c FROM maillog WHERE date > DATE_SUB(NOW(), INTERVAL $days+1 DAY) AND isspam=0 AND virusinfected=0 AND nameinfected=0 AND otherinfected=0";
    } else {
        $sql{1} = "SELECT DATE_FORMAT(DATE_SUB(NOW(), INTERVAL $days DAY), '%e %M %Y') d, COUNT(*) c FROM maillog WHERE date=DATE_SUB(NOW(), INTERVAL $days DAY)";
        $sql{2} = "SELECT DATE_FORMAT(DATE_SUB(NOW(), INTERVAL $days DAY), '%e %M %Y') d, COUNT(*) c FROM maillog WHERE date=DATE_SUB(NOW(), INTERVAL $days DAY) AND isspam=1";
        $sql{3} = "SELECT DATE_FORMAT(DATE_SUB(NOW(), INTERVAL $days DAY), '%e %M %Y') d, COUNT(*) c FROM maillog WHERE date=DATE_SUB(NOW(), INTERVAL $days DAY) AND virusinfected=1";
        $sql{4} = "SELECT DATE_FORMAT(DATE_SUB(NOW(), INTERVAL $days DAY), '%e %M %Y') d, COUNT(*) c FROM maillog WHERE date=DATE_SUB(NOW(), INTERVAL $days DAY) AND isspam=0 AND virusinfected=0 AND nameinfected=0 AND otherinfected=0";
    }

    for (my $i=1; $i<5; $i++) {
        my $sth = $dbh->prepare($sql{$i});
        $sth->execute() or die $dbh->errstr;

        if ($sth->rows > 0) {
            my $ref = $sth->fetchrow_hashref() or return;
            $val{$i} = $ref->{'c'};
            $date = $ref->{'d'};
        }
        $sth->finish();
    }

    my $per_spam = 0;
    if ($val{1} != 0) {
        $per_spam = (100/$val{1})*$val{2}
    }
    my $per_virus = 0;
    if ($val{1} != 0) {
        $per_virus = (100/$val{1})*$val{3}
    }
    my $per_clean = 0;
    if ($val{1} != 0) {
        $per_clean = (100/$val{1})*$val{4}
    }
    print($date.":\n");
    print("   messages: ".$val{1}."\n");
    printf("   spams:    %d (%2.2f%%)\n", $val{2}, $per_spam);
    printf("   viruses:  %d (%2.2f%%)\n", $val{3}, $per_virus);
    printf("   clean:    %d (%2.2f%%)\n", $val{4}, $per_clean);
}
