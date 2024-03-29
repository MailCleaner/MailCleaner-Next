#!/bin/bash
#
#   Mailcleaner - SMTP Antivirus/Antispam Gateway
#   Copyright (C) 2004 Olivier Diserens <olivier@diserens.ch>
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
#
#
#   This script will display the number of messages waiting on each of the 3
#   main spools which are:
#   Stage 1 for the incoming spool
#   Stage 2 for the filtering spool (antispam/antivirus processes)
#   Stage 4 for the outgoing spool
#
#   Usage:
#           check_spools.sh

SRCDIR=$(grep 'SRCDIR' /etc/mailcleaner.conf | cut -d ' ' -f3)
if [ "SRCDIR" = "" ]; then
	SRCDIR=/var/mailcleaner
fi
VARDIR=$(grep 'VARDIR' /etc/mailcleaner.conf | cut -d ' ' -f3)
if [ "VARDIR" = "" ]; then
	VARDIR=/var/mailcleaner
fi
EXIMBIN=/opt/exim4/bin/exim

echo -n "Stage 1:       "
$EXIMBIN -C $VARDIR/spool/tmp/exim/exim_stage1.conf -bpc

echo -n "Stage 2:       "
TYPE=$(grep -e '^MTA\s*=\s*eximms' $SRCDIR/etc/mailscanner/MailScanner.conf)
if [ "$TYPE" = "" ]; then
	$EXIMBIN -C $VARDIR/spool/tmp/exim/exim_stage2.conf -bpc
else
	ls $VARDIR/spool/exim_stage2/input/*.env 2>&1 | grep -v 'No such' | wc -l
fi

echo -n "Stage 4:       "
$EXIMBIN -C $VARDIR/spool/tmp/exim/exim_stage4.conf -bpc
