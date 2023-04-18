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
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

use v5.36;
use strict;
use warnings;
use utf8;

our $SRCDIR;
BEGIN {
    $SRCDIR = '/usr/mailcleaner';
}
use lib "$SRCDIR/lib";
require DB;

my $dryrun = 0;
if (defined($ARGV[0])) {
    if ($ARGV[0] eq '-d') {
        $dryrun = 1;
    } else {
        usage();
    }
}

my $db = DB::connect('master', 'mc_config');
my @rows = $db->getListOfHash("SELECT id, recipient, sender, type FROM wwlists");
die "Failed to fetch wwlists\n" unless @rows;

my %uniq;
my @dup;
foreach my $rule (@rows) {
    if (defined($uniq{$rule->{'sender'}}->{$rule->{'recipient'}}->{$rule->{'type'}})) {
        if ($dryrun) {
            print "$rule->{'id'} is a duplicate of $uniq{$rule->{'sender'}}->{$rule->{'recipient'}}->{$rule->{'type'}} (sender: '$rule->{'sender'}', recipient: '$rule->{'recipient'}', type: '$rule->{'type'}')\n";
        } else {
            push(@dup, $rule->{'id'});
        }
    } else {
        $uniq{$rule->{'sender'}}->{$rule->{'recipient'}}->{$rule->{'type'}} = $rule->{'id'};
    }
}

exit(0) if ($dryrun);

my @failed;
foreach (@dup) {
    unless ($db->execute("DELETE FROM wwlists WHERE id='$_';")) {
        print STDERR $?;
        push(@failed, $_);
    }
}
if (scalar(@failed)) {
    foreach (@failed) {
        print "Failed to delete $_\n";
    }
}
print "Deleted " . (scalar(@dup)-scalar(@failed)) . " of " . scalar(@dup) . " duplicates.\n";

sub usage
{
    print "usage: $0 [-d]

  -d    dryrun
    Simply print all of the duplicate rules, but don't delete them.\n";
    exit(0);
}
