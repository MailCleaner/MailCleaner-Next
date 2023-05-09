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
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.    See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA    02111-1307    USA
#
#
#   This module will just read the configuration file

use v5.36;
use strict;
use warnings;
use utf8;

package DB;
require Exporter;
use ReadConfig;
use DBI();

our @ISA = qw(Exporter);
our @EXPORT = qw(connect);
our $VERSION = 1.0;

sub connect($type,$db,$critical=0)
{
    if (!$type || $type !~ /slave|master|realmaster|custom/) {
        print "BADCONNECTIONTYPE\n";
        return "";
    }
    my $dbase = 'mc_config';
    if ($db) {
        $dbase = $db;
    }

    # determine socket to use
    my $conf = ReadConfig::getInstance();
    my $socket = $conf->getOption('VARDIR')."/run/mysql_master/mysqld.sock";
    if ($type =~ /slave/) {
        $socket = $conf->getOption('VARDIR')."/run/mysql_slave/mysqld.sock";
    }

    my $dbh;
    my $realmaster = 0;
    my $masterfile = $conf->getOption('VARDIR')."/spool/mailcleaner/master.conf";
    if ( ($type =~ /realmaster/ && -f $masterfile) || $type =~ /custom/) {
        my $host;
        my $port;
        my $password;
        if (open(my $MASTERFILE, '<', $masterfile)) {
            while (<$MASTERFILE>) {
                if (/HOST (\S+)/) { $host = $1; }
                if (/PORT (\S+)/) { $port = $1; }
                if (/PASS (\S+)/) { $password = $1; }
            }
            close $MASTERFILE;
        }
        if ($type =~ /custom/) {
            $host = $db->{'host'};
            $port = $db->{'port'};
            $password = $db->{'password'};
            $dbase = $db->{'database'};
        }
        if (! ( $host eq "" || $port eq "" || $password eq "") ) {
            $dbh = DBI->connect(
                "DBI:MariaDB:database=$dbase;host=$host:$port;",
                "mailcleaner", $password, {RaiseError => 0, PrintError => 0, AutoCommit => 1}
            ) or fatal_error("CANNOTCONNECTDB", $critical);
            $realmaster = 1;
        }
    }
    if ($realmaster < 1) {
        $dbh = DBI->connect(
            "DBI:MariaDB:database=$db;host=localhost;mariadb_socket=$socket",
            "mailcleaner", $conf->getOption('MYMAILCLEANERPWD'), {RaiseError => 0, PrintError => 0}
        ) or fatal_error("CANNOTCONNECTDB 2", $critical);
    }
    my $this = {
        dbh => $dbh,
        type => $type,
        critical => $critical,
    };

    return bless $this, "DB";
}

sub getType($this)
{
    return $this->{dbh};
}

sub ping($this)
{
    if (defined($this->{dbh})) {
        return $this->{dbh}->ping();
    }
}

sub disconnect($this)
{
    my $dbh = $this->{dbh};
    if ($dbh) {
        $dbh->disconnect();
    }
    $this->{dbh} = "";
    return 1;
}

sub fatal_error($msg,$critical=0)
{
    return 0 unless ($critical);
    die("$msg\n");
}

sub prepare($this,$query)
{
    my $dbh = $this->{dbh};

    my $prepared = $dbh->prepare($query);
    if (! $prepared) {
        print "WARNING, CANNOT EXECUTE ($query => ".$dbh->errstr.")\n";
        return 0;
    }
    return $prepared;
}


sub execute($this,$query,$nolock=0)
{
    my $dbh = $this->{dbh};

    if (!defined($dbh)) {
        print "WARNING, DB HANDLE IS NULL\n";
        return 0;
    }
    if (!$dbh->do($query)) {
        print "WARNING, CANNOT EXECUTE ($query => ".$dbh->errstr.")\n";
        return 0;
    }
    return 1;
}

sub commit($this,$query)
{
    my $dbh = $this->{dbh};

    if (! $dbh->commit()) {
        print "WARNING, CANNOT commit\n";
        return 0;
    }
    return 1;
}

sub getListOfHash($this,$query,$nowarnings=0)
{
    my $dbh = $this->{dbh};
    my @results;

    my $sth = $dbh->prepare($query);
    my $res = $sth->execute();
    if (!defined($res)) {
        if (! $nowarnings) {
            print "WARNING, CANNOT QUERY ($query => ".$dbh->errstr.")\n";
        }
        return @results;
    }
    while (my $ref = $sth->fetchrow_hashref()) {
        push @results, $ref;
    }

    $sth->finish();
    return @results;
}

sub getList($this,$query,$nowarnings=0)
{
    my $dbh = $this->{dbh};
    my @results;

    my $sth = $dbh->prepare($query);
    my $res = $sth->execute();
    if (!defined($res)) {
        if (! $nowarnings) {
            print "WARNING, CANNOT QUERY ($query => ".$dbh->errstr.")\n";
        }
        return @results;
    }
    while (my @ref = $sth->fetchrow_array()) {
        push @results, $ref[0];
    }

    $sth->finish();
    return @results;
}

sub getCount($this,$query)
{
    my $dbh = $this->{dbh};
    my $sth = $dbh->prepare($query);
    my $res = $sth->execute();

    my ($count) = $sth->fetchrow_array;

    return($count);
}


sub getHashRow($this,$query,$nowarnings=0)
{
    my $dbh = $this->{dbh};
    my %results;

    my $sth = $dbh->prepare($query);
    my $res = $sth->execute();
    if (!defined($res)) {
        if (! $nowarnings) {
            print "WARNING, CANNOT QUERY ($query => ".$dbh->errstr.")\n";
        }
        return %results;
    }

    my $ret = $sth->fetchrow_hashref();
    foreach my $key (keys %$ret ) {
        $results{$key} = $ret->{$key};
    }
    $sth->finish();
    return %results;
}

sub getLastID($this)
{
    my $res = 0;
    my $query = "SELECT LAST_INSERT_ID() as lid;";

    my $sth = $this->{dbh}->prepare($query);
    my $ret = $sth->execute();
    if (!$ret) {
        return $res;
    }
    $ret = $sth->fetchrow_hashref();
    if (!defined($ret)) {
        return $res;
    }

    if (defined($ret->{'lid'})) {
        return $ret->{'lid'};
    }
    return $res;
}

sub getError($this)
{
    my $dbh = $this->{dbh};

    if (defined($dbh->errstr)) {
        return $dbh->errstr;
    }
    return "";
}

sub setAutoCommit($this,$v=0)
{
    if ($v) {
        $this->{dbh}->{AutoCommit} = 1;
        return 1;
    }
    $this->{dbh}->{AutoCommit} = 0;
    return 0
}

1;
