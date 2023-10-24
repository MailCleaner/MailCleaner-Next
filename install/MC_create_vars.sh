#!/bin/bash

VARDIR=$(grep 'VARDIR' /etc/mailcleaner.conf | cut -d ' ' -f3)
if [ "VARDIR" = "" ]; then
	VARDIR=/var/mailcleaner
fi

UID=mailcleaner
GID=mailcleaner

function check_dir {
	if [ ! -d $1 ]; then
		echo "directory: $1 does not exists !"
		mkdir $1
		echo "directory: $1 created"
	else
		echo "directory $1 ok"
	fi
	chown $UID:$GID $1
}

check_dir $VARDIR
check_dir $VARDIR/log
check_dir $VARDIR/spool
check_dir $VARDIR/run
check_dir $VARDIR/spool/tmp
check_dir $VARDIR/log/mailcleaner
check_dir $VARDIR/spool/mailcleaner
check_dir $VARDIR/spool/mailcleaner/prefs
check_dir $VARDIR/spool/mailcleaner/counts
check_dir $VARDIR/spool/mailcleaner/stats
check_dir $VARDIR/spool/mailcleaner/scripts
check_dir $VARDIR/spool/mailcleaner/addresses
check_dir $VARDIR/spool/rrdtools
check_dir $VARDIR/spool/bogofilter
check_dir $VARDIR/spool/bogofilter/database
check_dir $VARDIR/spool/bogofilter/updates
check_dir $VARDIR/spool/learningcenter
check_dir $VARDIR/spool/learningcenter/stockspam
check_dir $VARDIR/spool/learningcenter/stockham
check_dir $VARDIR/spool/learningcenter/stockrandom
check_dir $VARDIR/spool/learningcenter/stockrandom/spam
check_dir $VARDIR/spool/learningcenter/stockrandom/spam/cur
check_dir $VARDIR/spool/learningcenter/stockrandom/ham
check_dir $VARDIR/spool/learningcenter/stockrandom/ham/cur
check_dir $VARDIR/run/mailcleaner
check_dir $VARDIR/run/mailcleaner/log_search
check_dir $VARDIR/run/mailcleaner/stats_search
