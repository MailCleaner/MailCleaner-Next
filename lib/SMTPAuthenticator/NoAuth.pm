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

package SMTPAuthenticator::NoAuth;

use v5.36;
use strict;
use warnings;
use utf8;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(create authenticate);
our $VERSION = 1.0;

sub create($server,$port,$params)
{
    my $self = {
        error_text => "No authentication scheme available",
        error_code => -1,
    };

    bless $self, "SMTPAuthenticator::NoAuth";
    return $self;
}

sub authenticate($self,$username,$password)
{
    error_text => "No authentication scheme available for user: $username",
    return 0;
}

1;
