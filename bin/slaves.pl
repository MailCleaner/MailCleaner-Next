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

use v5.36;
use strict;
use warnings;
use utf8;
use Carp qw( confess );

my ($SRCDIR);
BEGIN {
    if ($0 =~ m/(\S*)\/\S+.pl$/) {
        my $path = $1."/../lib";
        unshift (@INC, $path);
    }
    require ReadConfig;
    my $conf = ReadConfig::getInstance();
    $SRCDIR = $conf->getOption('SRCDIR') || '/usr/mailcleaner';
    unshift(@INC, $SRCDIR."/lib");
}

require DB;
use Term::ReadKey;

my $slave_dbh = DB::connect('slave', 'mc_config') || confess("ERROR: no slave database found on this system.\n");

view_slaves();

sub view_slaves
{
    my $sth =  $slave_dbh->prepare("SELECT id, hostname, port, ssh_pub_key  FROM slave") or die ("error in SELECT");
    $sth->execute() or die ("error in SELECT");
    my $el=$sth->rows;
    while (my $ref=$sth->fetchrow_hashref()) {
        printf $ref->{'hostname'}."\n";
    }
    $sth->finish();
}
