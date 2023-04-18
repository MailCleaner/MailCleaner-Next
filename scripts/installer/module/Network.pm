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
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

package module::Network;

use v5.36;
use strict;
use warnings;
use utf8;

require Exporter;
require DialogFactory;
require module::Interface;
require module::Resolver;

our @ISA = qw(Exporter);
our @EXPORT = qw(get ask do);
our $VERSION = 1.0;

sub get
{
    my $this = {
        networkfile => "/etc/network/interfaces",
        resolvfile => "/etc/resolv.conf"
    };

    bless $this, 'module::Network';
    return $this;
}

sub do
{
    my $this = shift;

    my $dfact = DialogFactory::get('InLine');
    my $dlg = $dfact->getYesNoDialog();

    my $config = "";
    $config .= "\nauto lo\n";
    $config .= "iface lo inet loopback\n";
    $config .= "\tpre-up modprobe ipv6\n";
    $config .= "\tpre-up echo 0 > /proc/sys/net/ipv6/conf/lo/disable_ipv6\n\n";

    my $int = module::Interface::get('eth0');
    $int->ask();
    $config .= $int->getConfig();

    my $resolv = module::Resolver::get();
    $resolv->setDNS(1, $int->getGateway());
    $resolv->ask();
    my $resconfig .= $resolv->getConfig();

    if (open(my $RESFILE, '>', $this->{resolvfile})) {
        print $RESFILE $resconfig;
        close $RESFILE;
    }
    if (open(my $NETFILE, '>', $this->{networkfile})) {
        print $NETFILE $config;
        close $NETFILE;

        `/etc/init.d/networking restart 2>&1 > /dev/null`;
    }
}

1;
