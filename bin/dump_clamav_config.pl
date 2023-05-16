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
#   This script will dump the clamav configuration file with the configuration
#   settings found in the database.
#
#   Usage:
#           dump_clamav_config.pl

use v5.36;
use strict;
use warnings;
use utf8;
use Carp qw( confess );

our ($conf, $SRCDIR, $VARDIR);
BEGIN {
    if ($0 =~ m/(\S*)\/\S+.pl$/) {
        my $path = $1."/../lib";
        unshift (@INC, $path);
    }
    require ReadConfig;
    $conf = ReadConfig::getInstance();
    $SRCDIR = $conf->getOption('SRCDIR');
    $VARDIR = $conf->getOption('VARDIR');
    unshift(@INC, $SRCDIR."/lib");
}

use lib_utils qw( open_as );
use DBI();

my $lasterror;

dump_file("clamav.conf");
dump_file("freshclam.conf");
dump_file("clamd.conf");
dump_file("clamspamd.conf");

if (-e "${VARDIR}/spool/mailcleaner/clamav-unofficial-sigs") {
    if (-e "${VARDIR}/spool/clamav/unofficial-sigs") {
        my @src = glob("${VARDIR}/spool/clamav/unofficial-sigs/*");
        foreach my $s (@src) {
            my $d = $s;
            $d =~ s/unofficial-sigs\///;
             unless (-e $d) {
                symlink($s, $d);
            }
        }
    } else {
        print "${VARDIR}/spool/clamav/unofficial-sigs does not exist. Run ${SRCDIR}/scripts/cron/update_antivirus.sh then try again\n";
    }
} else {
    my @dest = glob("${VARDIR}/spool/clamav/*");
    foreach my $d (@dest) {
        my $s = $d;
        $s =~ s/clamav/clamav\/unofficial-sigs/;
        if (-l $d && $s eq readlink($d)) {
            unlink($d);
        }
    }
}

#############################
sub dump_file($file)
{
    my $template_file = $SRCDIR."/etc/clamav/".$file."_template";
    my $target_file = $SRCDIR."/etc/clamav/".$file;

    my ($TEMPLATE, $TARGET);
    confess "Cannot open $template_file" unless ( $TEMPLATE = ${open_as($template_file,'<')} );
    confess "Cannot open $template_file" unless ( $TARGET = ${open_as($target_file)} );

    my $proxy_server = "";
    my $proxy_port = "";
    if ($conf->getOption('HTTPPROXY')) {
        if ($conf->getOption('HTTPPROXY') =~ m/http\:\/\/(\S+)\:(\d+)/) {
            $proxy_server = $1;
            $proxy_port = $2;
        }
    }

    while(<$TEMPLATE>) {
        my $line = $_;

        $line =~ s/__VARDIR__/${VARDIR}/g;
        $line =~ s/__SRCDIR__/${SRCDIR}/g;
        if ($proxy_server =~ m/\S+/) {
            $line =~ s/\#HTTPProxyServer __HTTPPROXY__/HTTPProxyServer $proxy_server/g;
            $line =~ s/\#HTTPProxyPort __HTTPPROXYPORT__/HTTPProxyPort $proxy_port/g;
        }

        print $TARGET $line;
    }

    if (($file eq "clamd.conf") && ( -e "/var/mailcleaner/spool/mailcleaner/mc-experimental-macros")) {
        print $TARGET "OLE2BlockMacros yes";
    }

    close $TEMPLATE;
    close $TARGET;

    return 1;
}
