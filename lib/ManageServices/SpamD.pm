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

package ManageServices::SpamD;

use v5.36;
use strict;
use warnings;
use utf8;

our @ISA = "ManageServices";

sub init($module,$super)
{
    my $self = $super->createModule( config($super) );
    use Data::Dump;
    print "DEBUG: " . Data::Dump::dump($self->{'module'}->{'daemonize'})."\n";
    bless $self, 'ManageServices::SpamD';

    return $self;
}

sub config($super)
{
    my $config = {
        'name'              => 'spamd',
        'cmndline'          => 'spamd.pid',
        'cmd'               => '/usr/sbin/spamd',
        'conffile'          => $super->{'conf'}->getOption('SRCDIR').'/etc/mailscanner/spamd.conf',
        'pidfile'           => $super->{'conf'}->getOption('VARDIR').'/run/spamassassin.pid',
        'logfile'           => $super->{'conf'}->getOption('VARDIR').'/log/mailscanner/spamd.log',
        'socket'            => $super->{'conf'}->getOption('VARDIR').'/run/spamassassin.sock',
        'children'          => 21,
        'user'              => 'mailcleaner',
        'group'             => 'mailcleaner',
        'siteconfig'        => $super->{'conf'}->getOption('SRCDIR').'/share/spamassassin',
        'daemonize'         => 0,
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
    $class->SUPER::doLog('Dumping SpamD config...', 'daemon');
    if (system($self->{'SRCDIR'}.'/bin/dump_custom_spamc_rules.pl 2>&1 >/dev/null')) {
        $class->SUPER::doLog('dump_custom_spamc_rules.pl failed', 'daemon');
    }
    if (system($self->{'SRCDIR'}.'/bin/dump_spamc_double_items.pl 2>&1 >/dev/null')) {
        $class->SUPER::doLog('dump_spamc_double_items.pl failed', 'daemon');
    }
    if (system($self->{'SRCDIR'}.'/bin/dump_mailscanner_config.pl 2>&1 >/dev/null')) {
        $class->SUPER::doLog('dump_mailscanner_config.pl failed', 'daemon');
    }
    if (system('/usr/bin/pyzor discover 2>/dev/null >/dev/null')) {
        $class->SUPER::doLog('/usr/bin/pyzor discover failed', 'daemon');
    }

    return 1;
}

sub preFork($self,$class)
{
    return 0;
}

sub mainLoop($self,$class)
{
    my $cmd = $self->{'cmd'};
    $class->SUPER::doLog("CMD: $cmd\n", 'daemon');
    open(my $CONF, '<', $self->{'conffile'})
        || die "Cannot open config file $self->{'conffile'}";
    while (my $line = <$CONF>) {
        if ($line =~ m/^#/) {
            next;
        } elsif ($line =~ m/^ *$/) {
            next;
        } elsif ($line =~ m/([^=]*) *= *(.*)/) {
            my ($op, $val) = ($1, $2);

            if ($op eq $val || $val eq "yes") {
                $cmd .= ' --' . $op;
            } elsif ($val ne "no") {
                $cmd .= ' --' . $op . '=' . $val;
            }
        } else {
            $self->SUPER::doLog("Invalid configuration line: $line", 'daemon');
        }
    }
    close($CONF);

    $class->SUPER::doLog("Running $cmd", 'daemon');
    system($cmd);

    return 1;
}

1;
