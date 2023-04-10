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

my $i = 0;
my $j = 0;

unlink '/usr/mailcleaner/share/spamassassin/double_item_uri.cf';

exit if ( ! -f '/usr/mailcleaner/share/spamassassin/double_item_uri.txt' );

open FH_TXT, '<', '/usr/mailcleaner/share/spamassassin/double_item_uri.txt';
open RULES, '>', '/usr/mailcleaner/share/spamassassin/double_item_uri.cf';
while (<FH_TXT>) {
        $_ =~ s/^\s*//;
        $_ =~ s/\s*$//;
        next if ( $_ =~ m/^#/ );
        my ($w1, $w2) = split(' ', $_);
        next if ( ! defined($w2) );
        print RULES "# auto generated rule to prevent links containing both $w1 and $w2\n";
        print RULES "uri __MC_URI_DBL_ITEM_$i /$w1.*$w2/i\n";
        $j = $i;
        $i++;
        print RULES "uri __MC_URI_DBL_ITEM_$i /$w2.*$w1/i\n";

        print RULES "\nmeta MC_URI_DBL_ITEM_$j ( __MC_URI_DBL_ITEM_$j || __MC_URI_DBL_ITEM_$i )\n";
        print RULES "describe MC_URI_DBL_ITEM_$j Link containing both $w1 and $w2\n";
        print RULES "score MC_URI_DBL_ITEM_$j 7.0\n\n";
        $i++;
}
close FH_TXT;
close RULES;
