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
#   This script will dump the mysql configuration file from the configuration
#   setting found in the database.
#
#   Usage:
#           dump_mysql_config.pl

use v5.36;
use strict;
use warnings;
use utf8;
use Carp qw( confess );

our ($conf, $SRCDIR, $VARDIR, $HOSTID);
BEGIN {
    if ($0 =~ m/(\S*)\/\S+.pl$/) {
        my $path = $1."/../lib";
        unshift (@INC, $path);
    }
    require ReadConfig;
    $conf = ReadConfig::getInstance();
    $SRCDIR = $conf->getOption('SRCDIR') || '/usr/mailcleaner';
    $VARDIR = $conf->getOption('VARDIR') || '/var/mailcleaner';
    confess "Failed to get HOSTID from '/etc/mailcleaner.conf'" unless ($HOSTID = $conf->getOption('HOSTID'));
}

use lib_utils qw(open_as);
use File::Path qw(make_path);
require DB;

our $DEBUG = 1;

## added 10 for migration ease
my %config;
$config{'HOSTID'} = ${HOSTID};
$config{'__MASTERID__'} = (${HOSTID} * 2) - 1 + 10;
$config{'__SLAVEID__'} = ${HOSTID} * 2 + 10;

## Avoid having unsychronized database when starting a new VA
my $FIRSTUPDATE_FLAG_RAN="${VARDIR}/run/configurator/updater4mc-ran";
if (-e $FIRSTUPDATE_FLAG_RAN){
    $config{'__BINARY_LOG_KEEP__'} = 21;
} else {
    $config{'__BINARY_LOG_KEEP__'} = 0;
}

my $lasterror = "";

my @stages = ('master', 'slave');
if (scalar(@ARGV)) {
    use List::Util qw (uniq);
    @stages = uniq(@ARGV);
    foreach (@stages) {
        confess "Invalid database $_" unless ($_ =~ /^(slave|master)$/);
    }
}
foreach (@stages) {
    confess "CANNOTDUMPMYSQLFILE" unless (dump_mysql_file($_,%config));
}

#############################
sub dump_mysql_file($stage,%config)
{
    my $template_file = "${SRCDIR}/etc/mysql/my_$stage.cnf_template";
    my $target_file = "${SRCDIR}/etc/mysql/my_$stage.cnf";

    my ($TEMPLATE, $TARGET);
    confess "Cannot open $template_file: $!" unless ($TEMPLATE = ${open_as($template_file, '<')});
    confess "Cannot open $target_file: $!" unless ($TARGET = ${open_as($target_file)});

    while(<$TEMPLATE>) {
        my $line = $_;

        $line =~ s/__VARDIR__/${VARDIR}/g;
        $line =~ s/__SRCDIR__/${SRCDIR}/g;

        foreach my $key (keys %config) {
            $line =~ s/$key/$config{$key}/g;
        }

        print $TARGET $line;
    }

    close $TEMPLATE;
    close $TARGET;

    return 1;
}
