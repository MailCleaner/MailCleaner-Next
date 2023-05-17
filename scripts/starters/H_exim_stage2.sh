#!/bin/bash

DELAY=2

export PATH=$PATH:/sbin:/usr/sbin

SRCDIR=$(grep 'SRCDIR' /etc/mailcleaner.conf | cut -d ' ' -f3)
if [ "$SRCDIR" = "" ]; then
	SRCDIR=/opt/mailcleaner
fi

$SRCDIR/etc/init.d/exim_stage2 stop 2>&1 >/dev/null
sleep $DELAY
PREVPROC=$(pgrep -f /etc/exim/exim_stage2)
if [ ! "$PREVPROC" = "" ]; then
	echo -n "FAILED"
	exit
else
	echo -n "SUCCESSFULL"
fi
