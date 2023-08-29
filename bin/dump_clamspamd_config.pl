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
#   This script will dump the clamspamd configuration file with the configuration
#   settings found in the database.
#
#   Usage:
#           dump_clamspamd_config.pl

use v5.36;
use strict;
use warnings;
use utf8;
use Carp qw( confess );

our ($SRCDIR, $VARDIR);
BEGIN {
    if ($0 =~ m/(\S*)\/\S+.pl$/) {
        my $path = $1."/../lib";
        unshift (@INC, $path);
    }
    require ReadConfig;
    my $conf = ReadConfig::getInstance();
    $SRCDIR = $conf->getOption('SRCDIR');
    $VARDIR = $conf->getOption('VARDIR');
    unshift(@INC, $SRCDIR."/lib");
}

use lib_utils qw( open_as );

my $lasterror;

my $uid = getpwnam( 'clamav' );
my $gid = getgrnam( 'mailcleaner' );

# Create necessary dirs/files if they don't exist
foreach my $dir (
    $VARDIR."/log/clamav/",
    $VARDIR."/run/clamav/",
    $VARDIR."/spool/clamspam/",
) {
    mkdir($dir) unless (-d $dir);
    chown($uid, $gid, $dir);
}

foreach my $file (
    glob($VARDIR."/log/clamav/*"),
    glob($VARDIR."/run/clamav/*"),
    glob($VARDIR."/spool/clamspam/*"),
) {
    chown($uid, $gid, $file);
}

# Configure sudoer permissions if they are not already
mkdir '/etc/sudoers.d' unless (-d '/etc/sudoers.d');
if (open(my $fh, '>', '/etc/sudoers.d/apache')) {
    print $fh "
User_Alias  CLAMAV = clamav
Runas_Alias ROOT = root
Cmnd_Alias  CLAMBIN = /usr/sbin/clamd

CLAMAV      * = (ROOT) NOPASSWD: CLAMBIN
";
}

# Add to mailcleaner and mailscanner groups if not already a member
`usermod -a -G mailcleaner clamav` unless (grep(/\bmailcleaner\b/, `groups clamav`));
`usermod -a -G mailscanner clamav` unless (grep(/\bmailscanner\b/, `groups clamav`));

# SystemD auth causes timeouts
`sed -iP '/^session.*pam_systemd.so/d' /etc/pam.d/common-session`;

# Dump configuration
dump_file("clamspamd.conf");

#############################
sub dump_file($file)
{
    my $template_file = $SRCDIR."/etc/clamav/".$file."_template";
    my $target_file = $SRCDIR."/etc/clamav/".$file;

    my ($TEMPLATE, $TARGET);
    confess "Cannot open $template_file" unless ( $TEMPLATE = ${open_as($template_file,'<')} );
    confess "Cannot open $template_file" unless ( $TARGET = ${open_as($target_file)} );

    while(<$TEMPLATE>) {
        my $line = $_;

        $line =~ s/__VARDIR__/${VARDIR}/g;

        print $TARGET $line;
    }

    close $TEMPLATE;
    close $TARGET;

    return 1;
}
