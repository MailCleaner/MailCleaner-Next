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

package ManageServices::ClamSpamD;

use v5.36;
use strict;
use warnings;
use utf8;

our @ISA = "ManageServices";

sub init($module,$super)
{
    my $self = $super->createModule( config($super) );
    bless $self, 'ManageServices::ClamSpamD';

    return $self;
}

sub config($super)
{
    my $config = {
        'name'              => 'clamspamd',
        'cmndline'          => 'clamav/clamspamd.conf',
        'cmd'               => '/opt/clamav/sbin/clamd',
        'conffile'          => $super->{'conf'}->getOption('SRCDIR').'/etc/clamav/clamspamd.conf',
        'pidfile'           => $super->{'conf'}->getOption('VARDIR').'/run/clamav/clamspamd.pid',
        'logfile'           => $super->{'conf'}->getOption('VARDIR').'/log/clamav/clamspamd.log',
        'localsocket'       => $super->{'conf'}->getOption('VARDIR').'/run/clamav/clamspamd.sock',
        'children'          => 1,
        'user'              => 'clamav',
        'group'             => 'clamav',
        'daemonize'         => 'yes',
        'forks'             => 0,
        'nouserconfig'      => 'yes',
        'syslog_facility'   => '',
        'debug'             => 0,
        'log_sets'          => 'all',
        'loglevel'          => 'info',
        'timeout'           => 5,
        'checktimer'        => 10,
        'actions'           => {},
    };

    return $config;
}

sub setup($self,$class)
{
    return 0;
}

sub preFork($self,$class)
{
    return 0;
}

sub mainLoop($self,$class)
{
    my $cmd = $self->{'cmd'};
    $cmd .= ' --config-file=' . $self->{'conffile'};
    $class->SUPER::doLog("Running $cmd", 'daemon');
    system($cmd);

    return 1;
}

1;
