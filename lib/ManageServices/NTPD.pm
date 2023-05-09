#!/usr/bin/env perl
#
#   Mailcleaner - SMTP Antivirus/Antispam Gateway
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

package ManageServices::NTPD;

use v5.36;
use strict;
use warnings;
use utf8;

our @ISA = "ManageServices";

sub init($module,$class)
{
    my $self = $class->SUPER::createModule( config($class) );
    bless $self, 'ManageServices::NTPD';

    return $self;
}

sub config($class)
{
    my $config = {
        'name'              => 'ntpd',
        'cmndline'          => '/usr/sbin/ntpd',
        'cmd'               => '/usr/sbin/ntpd',
        'pidfile'           => '/var/run/ntpd.pid',
        'user'              => 'ntp',
        'group'             => 'ntp',
        'daemonize'         => 'no',
        'forks'             => 0,
        'syslog_facility'   => 'local1',
        'debug'             => 0,
        'log_sets'          => 'all',
        'loglevel'          => 'info',
        'timeout'           => 5,
        'actions'           => {},
    };

    return $config;
}

sub setup($self,$class)
{
    $self->{'cmd'} .= " -p $self->{'pidfile'} -g -u $self->{'uid'}:$self->{'gid'}";

    return 1;
}

sub preFork($self,$class)
{
    return 0;
}

sub mainLoop($self,$class)
{
    my $cmd = $self->{'cmd'};
    $self->doLog("Running $cmd", 'daemon');
    system("$cmd");

    return 1;
}

1;
