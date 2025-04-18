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
#   This script will dump the snmp configuration file from the configuration
#   setting found in the database.
#
#   Usage:
#           dump_snmp_config.pl

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
    $SRCDIR = $conf->getOption('SRCDIR') || '/usr/mailcleaner';
    $VARDIR = $conf->getOption('VARDIR') || '/var/mailcleaner';
}

use lib_utils qw(open_as);
use File::Path qw(mkpath);
require DB;
require GetDNS;

our $DEBUG = 1;
our $uid = getpwnam('mailcleaner');
our $gid = getpwnam('mailcleaner');

my $system_mibs_file = '/usr/share/snmp/mibs/MAILCLEANER-MIB.txt';
if ( ! -d '/usr/share/snmp/mibs') {
    mkpath('/usr/share/snmp/mibs');
}
my $mc_mib_file = "${SRCDIR}/www/guis/admin/public/downloads/MAILCLEANER-MIB.txt";

my $lasterror = "";

our $dbh = DB::connect('slave', 'mc_config');

my %snmpd_conf;
confess "Error fetching snmp config: $!" unless %snmpd_conf = get_snmpd_config();

my %master_hosts;
%master_hosts = get_master_config();

confess "Error dumping snmp config: $!" unless dump_snmpd_file();

if ( !-d "/var/mailcleaner/log/snmpd/") {
    mkdir("/var/mailcleaner/log/snmpd/") || confess("Failed to create '/var/mailcleaner/log/snmpd/'\n");
    chown($uid, $gid, "/var/mailcleaner/log/snmpd/");
}
if (-f $system_mibs_file) {
    unlink($system_mibs_file);
}
symlink($mc_mib_file,$system_mibs_file);
chown($uid, $gid, $system_mibs_file);

symlink($SRCDIR.'/etc/apparmor', '/etc/apparmor.d/mailcleaner') unless (-e '/etc/apparmor.d/mailcleaner');

sub setup_snmpd_dir() {
    my $include = 0;
    if ( -e "/etc/snmp/snmpd.conf") {
        if (open(my $fh, '<', "/etc/snmp/snmpd.conf")) {
            while (<$fh>) {
                if ($_ =~ m#includeDir\s+/etc/snmp/snmpd.conf.d#) {
                    $include = 1;
                }
                last;
            }
            close($fh);
        } else {
            confess("Failed to read '/etc/snmp/snmpd.conf'\n");
        }
    }
    unless ($include) {
        if (open(my $fh, '>', "/etc/snmp/snmpd.conf")) {
            print $fh 'includeDir /etc/snmp/snmpd.conf.d';
            close($fh);
            $include = 1;
        } else {
            confess("Failed to open '/etc/snmp/snmpd.conf' for writing");
        }
    }
    if ( !-d "/etc/snmp/snmpd.conf.d") {
        mkdir("/etc/snmp/snmpd.conf.d") || confess("Failed to create '/etc/snmp/snmpd.conf.d'\n");
    }
    return 1;
}

sub dump_snmpd_file()
{
    setup_snmpd_dir() || confess("Failed to create/verify '/etc/snmp/snmpd.conf.d'\n");

    my $template_file = "${SRCDIR}/etc/snmp/snmpd.conf_template";
    my $target_file = "/etc/snmp/snmpd.conf.d/mailcleaner.conf";

    my $ipv6 = 0;
    if (open(my $interfaces, '<', '/etc/network/interfaces')) {
        while (<$interfaces>) {
            if ($_ =~ m/iface \S+ inet6/) {
                $ipv6 = 1;
                last;
            }
        }
        close($interfaces);
    }

    my ($TEMPLATE, $TARGET);
    confess "Cannot open $template_file: $!" unless ($TEMPLATE = ${open_as($template_file, '<')} );
    confess "Cannot open $target_file: $!" unless ($TARGET = ${open_as($target_file)} );

    my @ips = expand_host_string($snmpd_conf{'__ALLOWEDIP__'}.' 127.0.0.1',('dumper'=>'snmp/allowedip'));
    foreach my $ip ( keys(%master_hosts) ) {
        print $TARGET "com2sec local     $ip     $snmpd_conf{'__COMMUNITY__'}\n";
        print $TARGET "com2sec6 local     $ip     $snmpd_conf{'__COMMUNITY__'}\n";
    }
    foreach my $ip (@ips) {
        print $TARGET "com2sec local     $ip    $snmpd_conf{'__COMMUNITY__'}\n";
        if ($ipv6) {
            print $TARGET "com2sec6 local     $ip     $snmpd_conf{'__COMMUNITY__'}\n";
        }
    }

    while(<$TEMPLATE>) {
        my $line = $_;

        $line =~ s/__VARDIR__/${VARDIR}/g;
        $line =~ s/__SRCDIR__/${SRCDIR}/g;

        print $TARGET $line;
    }

    my @disks = split(/\:/, $snmpd_conf{'__DISKS__'});
    foreach my $disk (@disks) {
        print $TARGET "disk      $disk   100000\n";
    }

    close $TEMPLATE;
    close $TARGET;

    chown($uid, $gid, "/etc/snmp/snmpd.conf.d", "/log/snmpd.log", $TARGET);
    return 1;
}

#############################
sub get_snmpd_config
{
    my %config;

    my $sth = $dbh->prepare("SELECT allowed_ip, community, disks FROM snmpd_config");
    confess "CANNOTEXECUTEQUERY $dbh->errstr" unless $sth->execute();

    return unless ($sth->rows);
    my $ref;
    confess "CANNOTFETCHROWS $dbh->errstr" unless $ref = $sth->fetchrow_hashref();

    $config{'__ALLOWEDIP__'} = join(' ',expand_host_string($ref->{'allowed_ip'},('dumper'=>'snmp/allowedip')));
    $config{'__COMMUNITY__'} = $ref->{'community'};
    $config{'__DISKS__'} = $ref->{'disks'};

    $sth->finish();
    return %config;
}

#############################
sub get_master_config
{
    my %masters;

    my $sth = $dbh->prepare("SELECT hostname FROM master");
    confess "CANNOTEXECUTEQUERY $dbh->errstr" unless $sth->execute();

    return unless ($sth->rows);
    my $ref;
    while ($ref = $sth->fetchrow_hashref()) {
        $masters{$ref->{'hostname'}} = 1;
    }

    $sth->finish();
    return %masters;
}

sub expand_host_string($string, %args)
{
    my $dns = GetDNS->new();
    return $dns->dumper($string,%args);
}
