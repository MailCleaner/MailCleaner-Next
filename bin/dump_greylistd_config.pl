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
#   This script will dump the exim configuration file from the configuration
#   setting found in the database.
#
#   Usage:
#           dump_greylistd_config.pl
#

use v5.36;
use strict;
use warnings;
use utf8;
use Carp qw( confess );

my ($conf, $SRCDIR, $VARDIR, $MYMAILCLEANERPWD);
BEGIN {
    if ($0 =~ m/(\S*)\/\S+.pl$/) {
        my $path = $1."/../lib";
        unshift (@INC, $path);
    }
    require ReadConfig;
    $conf = ReadConfig::getInstance();
    $SRCDIR = $conf->getOption('SRCDIR') || '/usr/mailcleaner';
    $VARDIR = $conf->getOption('VARDIR') || '/var/mailcleaner';
    confess "Failed to get DB password" unless ($MYMAILCLEANERPWD = $conf->getOption('MYMAILCLEANERPWD'));
}

use lib_utils qw(open_as);
use File::Touch;

require DB;

my $DEBUG = 0;

my %greylist_conf = get_greylist_config();

my $uid = getpwnam( 'mailcleaner' );
my $gid = getgrnam( 'mailcleaner' );

dump_greylistd_file(\%greylist_conf);

dump_domain_to_avoid($greylist_conf{'__AVOID_DOMAINS_'});

# This file should be created by dump_domains.pl, but in case it does not exist, we need it
my $domainsfile = "${VARDIR}/spool/tmp/mailcleaner/domains_to_greylist.list";
if ( ! -f $domainsfile) {
    touch($domainsfile);
    chown($uid, $gid, $domainsfile);
}

sub get_greylist_config()
{
    my $slave_db = DB::connect('slave', 'mc_config');

    my %configs = $slave_db->getHashRow(
        "SELECT retry_min, retry_max, expire, avoid_domains FROM greylistd_config"
    );
    my %ret;

    $ret{'__RETRYMIN__'} = $configs{'retry_min'};
    $ret{'__RETRYMAX__'} = $configs{'retry_max'};
    $ret{'__EXPIRE__'} = $configs{'expire'};
    $ret{'__AVOID_DOMAINS_'} = $configs{'avoid_domains'};

    return %ret;
}

#############################
sub dump_domain_to_avoid($domains)
{
    my @domains_to_avoid;
    if (! $domains eq "") {
        @domains_to_avoid = split /\s*[\,\:\;]\s*/, $domains;
    }

    my $dir = "${VARDIR}/spool/tmp/mailcleaner/";
    make_path($dir, {'mode'=>0755,'user'=>$uid,'group'=>$gid}) unless ( -d $dir );
    my $file = "${dir}/domains_to_avoid_greylist.list";
    my $DOMAINTOAVOID;
    confess "Cannot open $file: $!" unless ($DOMAINTOAVOID = ${open_as($file)} );

    foreach my $adomain (@domains_to_avoid) {
        print $DOMAINTOAVOID $adomain."\n";
    }
    close $DOMAINTOAVOID;
}

#############################
sub dump_greylistd_file($href)
{
    my %greylist_conf = %{$href};

    my $dir = "${SRCDIR}/etc/greylistd";
    make_path($dir, {'mode'=>0755,'user'=>$uid,'group'=>$gid}) unless ( -e $dir );

    my $template_file = "${dir}/greylistd.conf_template";
    my $target_file = "${dir}/greylistd.conf";

    my ($TEMPLATE, $TARGET);
    confess "Cannot open $template_file: $!\n" unless ($TEMPLATE = ${open_as($template_file, '<')} );
    confess "Cannot open $target_file: $!\n" unless ($TARGET = ${open_as($target_file)} );

    while(<$TEMPLATE>) {
        my $line = $_;

        $line =~ s/__VARDIR__/$VARDIR/g;
        $line =~ s/__SRCDIR__/$SRCDIR/g;

        foreach my $key (keys %greylist_conf) {
            $line =~ s/$key/$greylist_conf{$key}/g;
        }

        print $TARGET $line;
    }

    close $TEMPLATE;
    close $TARGET;
}
