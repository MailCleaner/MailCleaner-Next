#!/usr/bin/env bash

if [ -z $SRCDIR ]; then
    SRCDIR="/usr/mailcleaner"
fi

cd $SRCDIR/scripts/systemd
for unit in `ls`; do
    if [[ -e /etc/systemd/system/$unit ]]; then
	if [[ -s /etc/systemd/system/$unit ]]; then
	    echo "$unit is already symlinked"
        elif [[ -d $SRCDIR/scripts/systemd/$unit ]]; then
	    if [[ -e /etc/systemd/system/$unit/overrides.conf ]]; then
	    	if [[ -s /etc/systemd/system/$unit/overrides.conf ]]; then
	            echo "$unit is already symlinked"
		elif [[ "$1" -eq '-f' ]]; then
		    echo "Overwriting $SRCDIR/scripts/systemd/$unit/overrides.conf with /etc/systemd/system/$unit/overrides.conf"
		    rm -rf /etc/systemd/system/$unit
		    ln -s $SRCDIR/scripts/systemd/$unit/overrides.conf /etc/systemd/system/$unit/
		else
		    echo "Error: /etc/systemd/system/$unit/overrides.conf already exists and is not a link to $SRCDIR/scripts/systemd/$unit/overrides.conf"
		fi
	    else
		echo "Linking $SRCDIR/scripts/systemd/$unit/overrides.conf to /etc/systemd/system/$unit/"
		ln -s $SRCDIR/scripts/systemd/$unit/overrides.conf /etc/systemd/system/$unit/
	    fi
        elif [[ "$1" -eq '-f' ]]; then
            echo "Overwriting $SRCDIR/scripts/systemd/$unit with /etc/systemd/system/$unit"
            rm -rf /etc/systemd/system/$unit
            ln -s $SRCDIR/scripts/systemd/$unit /etc/systemd/system/$unit
	else
	    echo "Error: /etc/systemd/system/$unit already exists and is not a link to $SRCDIR/scripts/systemd/$unit"
	fi
    else
	echo "Linking $SRCDIR/scripts/systemd/$unit to /etc/systemd/system/$unit"
        ln -s $SRCDIR/scripts/systemd/$unit /etc/systemd/system/
    fi
done
