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

if ($0 =~ m/(\S*)\/\S+.pl$/) {
    my $path = $1."/../lib";
    unshift (@INC, $path);
}

use DBI();
use Term::ReadKey;

my %config = readConfig("/etc/mailcleaner.conf");

my $slave_dbh = DBI->connect("DBI:mysql:database=mc_config;mysql_socket=$config{'VARDIR'}/run/mysql_slave/mysqld.sock",
                                        "mailcleaner","$config{'MYMAILCLEANERPWD'}", {RaiseError => 0, PrintError => 0} );
if (!$slave_dbh) {
	printf ("ERROR: no slave database found on this system.\n");
	exit 1;
}

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

sub readConfig
{
    my $configfile = shift;
    my %config;
    my ($var, $value);

    open (my $CONFIG, '<', $configfile) or die "Cannot open $configfile: $!\n";
    while (<$CONFIG>) {
        chomp;              # no newline
        s/#.*$//;           # no comments
        s/^\*.*$//;         # no comments
        s/;.*$//;           # no comments
        s/^\s+//;           # no leading white
        s/\s+$//;           # no trailing white
        next unless length; # anything left?
        my ($var, $value) = split(/\s*=\s*/, $_, 2);
        $config{$var} = $value;
    }
    close $CONFIG;
    return %config;
}
