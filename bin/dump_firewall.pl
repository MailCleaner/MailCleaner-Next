#!/usr/bin/env perl
#
# Mailcleaner - SMTP Antivirus/Antispam Gateway
# Copyright (C) 2004 Olivier Diserens <olivier@diserens.ch>
# Copyright (C) 2023 John Mertz <git@john.me.tz>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#
# This script will dump the firewall script
#
# Usage:
#   dump_firewall.pl


use v5.36;
use strict;
use warnings;
use utf8;
use Carp qw( confess );

my ($conf, $SRCDIR);
BEGIN {
    if ($0 =~ m/(\S*)\/\S+.pl$/) {
        my $path = $1."/../lib";
        unshift (@INC, $path);
    }
    require ReadConfig;
    $conf = ReadConfig::getInstance();
    $SRCDIR = $conf->getOption('SRCDIR') || '/usr/mailcleaner';
}

use lib_utils qw(open_as);

use Net::DNS;
require GetDNS;
require DB;

my $DEBUG = 1;

my %services = (
    'web' => ['80|443', 'TCP'],
    'mysql' => ['3306:3307', 'TCP'],
    'snmp' => ['161', 'UDP'],
    'ssh' => ['22', 'TCP'],
    'mail' => ['25', 'TCP'],
    'soap' => ['5132', 'TCP']
);
our $iptables = "/usr/sbin/iptables";
our $ip6tables = "/usr/sbin/ip6tables";
our $ipset = "/usr/sbin/ipset";

my $has_ipv6 = 0;

my $dbh = DB::connect('slave', 'mc_config');

my %masters_slaves = get_masters_slaves();

my $dnsres = Net::DNS::Resolver->new;

# do we have ipv6 ?
if (open(my $interfaces, '<', '/etc/network/interfaces')) {
    while (<$interfaces>) {
        if ($_ =~ m/iface \S+ inet6/) {
            $has_ipv6 = 1;
            last;
        }
    }
    close($interfaces);
}

my %rules;
get_default_rules(\%rules);
get_external_rules(\%rules);

do_start_script(\%rules);
do_stop_script(\%rules);

############################
sub get_masters_slaves()
{
    my %hosts;

    my $sth = $dbh->prepare("SELECT hostname from master");
    confess("CANNOTEXECUTEQUERY $dbh->errstr") unless $sth->execute();

    while (my $ref = $sth->fetchrow_hashref() ) {
         $hosts{$ref->{'hostname'}} = 1;
    }
    $sth->finish();

    $sth = $dbh->prepare("SELECT hostname from slave");
    confess("CANNOTEXECUTEQUERY $dbh->errstr") unless $sth->execute();

    while (my $ref = $sth->fetchrow_hashref() ) {
        $hosts{$ref->{'hostname'}} = 1;
    }
    $sth->finish();
    return %hosts;

}

sub get_default_rules($rules)
{
    foreach my $host (keys %masters_slaves) {
        next if ($host =~ /127\.0\.0\.1/ || $host =~ /^\:\:1$/);

        $rules->{"$host mysql TCP"} = [ $services{'mysql'}[0], $services{'mysql'}[1], $host];
        $rules->{"$host snmp UDP"} = [ $services{'snmp'}[0], $services{'snmp'}[1], $host];
        $rules->{"$host ssh TCP"} = [ $services{'ssh'}[0], $services{'ssh'}[1], $host];
        $rules->{"$host soap TCP"} = [ $services{'soap'}[0], $services{'soap'}[1], $host];
    }
    my @subs = getSubnets();
    foreach my $sub (@subs) {
        $rules->{"$sub ssh TCP"} = [ $services{'ssh'}[0], $services{'ssh'}[1], $sub ];
    }
}

sub get_external_rules($rules)
{
    my $sth = $dbh->prepare("SELECT service, port, protocol, allowed_ip FROM external_access");
    confess("CANNOTEXECUTEQUERY $dbh->errstr") unless $sth->execute();

    while (my $ref = $sth->fetchrow_hashref() ) {
         #next if ($ref->{'allowed_ip'} !~ /^(\d+.){3}\d+\/?\d*$/);
         next if ($ref->{'port'} !~ /^\d+[\:\|]?\d*$/);
         next if ($ref->{'protocol'} !~ /^(TCP|UDP|ICMP)$/i);
         foreach my $ip (expand_host_string($ref->{'allowed_ip'},('dumper'=>'snmp/allowedip'))) {
             # IPs already validated and converted to CIDR in expand_host_string, just remove non-CIDR entries
             if ($ip =~ m#/\d+$#) {
                 $rules->{$ip." ".$ref->{'service'}." ".$ref->{'protocol'}} = [ $ref->{'port'}, $ref->{'protocol'}, $ip];
             }
         }
    }

    ## check snmp UDP
    foreach my $rulename (keys %rules) {
        if ($rulename =~ m/([^,]+) snmp/) {
            $rules->{$1." snmp UDP"} = [ 161, 'UDP', $rules->{$rulename}[2]];
        }
    }

    ## enable submission port
    foreach my $rulename (keys %rules) {
        if ($rulename =~ m/([^,]+) mail/) {
            $rules->{$1." submission TCP"} = [ 587, 'TCP', $rules->{$rulename}[2]];
        }
    }
    ## do we need obsolete SMTP SSL port ?
    $sth = $dbh->prepare("SELECT tls_use_ssmtp_port FROM mta_config where stage=1");
    confess("CANNOTEXECUTEQUERY $dbh->errstr") unless $sth->execute();
    while (my $ref = $sth->fetchrow_hashref() ) {
        if ($ref->{'tls_use_ssmtp_port'} > 0) {
            foreach my $rulename (keys %rules) {
                if ($rulename =~ m/([^,]+) mail/) {
                    $rules->{$1." smtps TCP"} = [ 465, 'TCP', $rules->{$rulename}[2] ];
                }
            }
        }
    }
}

sub do_start_script($rules)
{
    my %rules = %{$rules};
    my $start_script = "${SRCDIR}/etc/firewall/start";
    unlink($start_script);

    my $START;
    confess "Cannot open $start_script" unless ( $START = ${open_as($start_script)} );

    print $START "#!/bin/sh\n";

    print $START "/sbin/modprobe ip_tables\n";
    if ($has_ipv6) {
        print $START "/sbin/modprobe ip6_tables\n";
    }

    print $START "\n# policies\n";
    print $START $iptables." -P INPUT DROP\n";
    print $START $iptables." -P FORWARD DROP\n";
    if ($has_ipv6) {
        print $START $ip6tables." -P INPUT DROP\n";
        print $START $ip6tables." -P FORWARD DROP\n";
    }

    print $START "\n# bad packets:\n";
    print $START $iptables." -A INPUT -p tcp ! --syn -m state --state NEW -j DROP\n";
    if ($has_ipv6) {
        print $START $ip6tables." -A INPUT -p tcp ! --syn -m state --state NEW -j DROP\n";
    }

    print $START "# local interface\n";
    print $START $iptables." -A INPUT -p ALL -i lo -j ACCEPT\n";
    if ($has_ipv6) {
        print $START $ip6tables." -A INPUT -p ALL -i lo -j ACCEPT\n";
    }

    print $START "# accept\n";
    print $START $iptables." -A INPUT -p ALL -m state --state ESTABLISHED,RELATED -j ACCEPT\n";
    if ($has_ipv6) {
        print $START $ip6tables." -A INPUT -p ALL -m state --state ESTABLISHED,RELATED -j ACCEPT\n";
    }

    print $START $iptables." -A INPUT -p ICMP --icmp-type 8 -j ACCEPT\n";
    if ($has_ipv6) {
        print $START $ip6tables." -A INPUT -p ipv6-icmp -j ACCEPT\n";
    }

    my $globals = {
        '4' => {},
        '6' => {}
    };
    foreach my $description (sort keys %rules) {
        my @ports = split '\|', $rules{$description}[0];
        my @protocols = split '\|', $rules{$description}[1];
        foreach my $port (@ports) {
            foreach my $protocol (@protocols) {
                my $host = $rules{$description}[2];
                # globals
                if ($host eq '0.0.0.0/0' || $host eq '::/0') {
                    next if ($globals->{'4'}->{$port}->{$protocol});
                    print $START "\n# $description\n";
                    print $START $iptables." -A INPUT -p ".$protocol." --dport ".$port." -j ACCEPT\n";
                    $globals->{'4'}->{$port}->{$protocol} = 1;
                    if ($has_ipv6) {
                        print $START $ip6tables." -A INPUT -p ".$protocol." --dport ".$port." -j ACCEPT\n";
                        $globals->{'6'}->{$port}->{$protocol} = 1;
                    }
                # IPv6
                } elsif ($host =~ m/\:/) {
                    next unless ($has_ipv6);
                    next if ($globals->{'6'}->{$port}->{$protocol});
                    print $START "\n# $description\n";
                    print $START $ip6tables." -A INPUT -p ".$protocol." --dport ".$port." -s ".$host." -j ACCEPT\n";
                # IPv4
                } elsif ($host =~ m/(\d+\.){3}\d+(\/\d+)?$/) {
                    next if ($globals->{'4'}->{$port}->{$protocol});
                    print $START "\n# $description\n";
                    print $START $iptables." -A INPUT -p ".$protocol." --dport ".$port." -s ".$host." -j ACCEPT\n";
                # Hostname
                } else {
                    next if ($globals->{'4'}->{$port}->{$protocol});
                    print $START "\n# $description\n";
                    print $START $iptables." -A INPUT -p ".$protocol." --dport ".$port." -s ".$host." -j ACCEPT\n";
                    if ($has_ipv6) {
                        my $reply = $dnsres->query($host, "AAAA");
                        if ($reply) {
                            print $START $ip6tables." -A INPUT -p ".$protocol." --dport ".$port." -s ".$host." -j ACCEPT\n";
                        }
                    }
                }
            }
        }
    }

    my @blacklist_files = ('/usr/mailcleaner/etc/firewall/blacklist.txt', '/usr/mailcleaner/etc/firewall/blacklist_custom.txt');
    my $blacklist = 0;
    my $blacklist_script = '/usr/mailcleaner/etc/firewall/blacklist';
    unlink $blacklist_script;
    my $BLACKLIST;
    foreach my $blacklist_file (@blacklist_files) {
        my $BLACK_IP;
        if ( -e $blacklist_file ) {
            if ( $blacklist == 0 ) {
                confess ("Failed to open $blacklist_script: $!\n") unless ($BLACKLIST = ${open_as($blacklist_script, ">>", 0755)});
                print $BLACKLIST "#!/bin/sh\n\n";
                print $BLACKLIST "$ipset -N blacklist nethash\n\n";
                $blacklist = 1;
            }
            confess ("Failed to open $blacklist_file: $!\n") unless ($BLACK_IP = ${open_as($blacklist_file, "<")});
            foreach my $IP (<$BLACK_IP>) {
                chomp($IP);
                print $BLACKLIST "$ipset add blacklist $IP\n"
            }
            close $BLACK_IP;
        }
    }
    if ( $blacklist == 1 ) {
        print $BLACKLIST "\n$iptables -I INPUT -m set --match-set blacklist src -j REJECT\n";
        print $START "\n$blacklist_script\n";
    }

    close $BLACKLIST;
    close $START;
}

sub do_stop_script($rules)
{
    my %rules = %{$rules};
    my $stop_script = "${SRCDIR}/etc/firewall/stop";
    unlink($stop_script);

    my $STOP;
    confess "Cannot open $stop_script" unless ( $STOP = ${open_as($stop_script, '>', 0755)} );

    print $STOP "#!/bin/sh\n";

    print $STOP $iptables." -P INPUT ACCEPT\n";
    print $STOP $iptables." -P FORWARD ACCEPT\n";
    print $STOP $iptables." -P OUTPUT ACCEPT\n";
    if ($has_ipv6) {
        print $STOP $ip6tables." -P INPUT ACCEPT\n";
        print $STOP $ip6tables." -P FORWARD ACCEPT\n";
        print $STOP $ip6tables." -P OUTPUT ACCEPT\n";
    }

    print $STOP $iptables." -F\n";
    print $STOP $iptables." -X\n";
    if ($has_ipv6) {
        print $STOP $ip6tables." -F\n";
        print $STOP $ip6tables." -X\n";
    }

    close $STOP;
}

sub getSubnets()
{
    my $ifconfig = `/sbin/ifconfig`;
    my @subs = ();
    foreach my $line (split("\n", $ifconfig)) {
        if ($line =~ m/\s+inet\ addr:([0-9.]+)\s+Bcast:[0-9.]+\s+Mask:([0-9.]+)/) {
            my $ip = $1;
            my $mask = $2;
            if ($mask && $mask =~ m/\d/) {
                my $ipcalc = `/usr/bin/ipcalc $ip $mask`;
                foreach my $subline (split("\n", $ipcalc)) {
                     if ($subline =~ m/Network:\s+([0-9.]+\/\d+)/) {
                        push @subs, $1;
                     }
                }
            }
        }
    }
    return @subs;
}

sub expand_host_string($string, %args)
{
    my $dns = GetDNS->new();
    return $dns->dumper($string,%args);
}
