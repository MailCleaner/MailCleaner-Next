#! /bin/bash
#
#   Mailcleaner - SMTP Antivirus/Antispam Gateway
#   Copyright (C) 2004-2014 Olivier Diserens <olivier@diserens.ch>
#   Copyright (C) 2015-2017 Mentor Reka <reka.mentor@gmail.com>
#   Copyright (C) 2015-2017 Florian Billebault <florian.billebault@gmail.com>
#   Copyright (C) 2024 John Mertz <git@john.me.tz>
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
#   This script will install pyenv, python 3.12.1 and MailCleaner library
#
VARDIR="/var/mailcleaner"
cd $VARDIR

if [ -f $VARDIR/log/mailcleaner/install_pyenv.log ]; then
    rm $VARDIR/log/mailcleaner/install_pyenv.log
fi

FREE_SPACE=$(df -k /var/mailcleaner | tail -1 | awk '{print $4}')

if [ $FREE_SPACE -lt 600000 ]; then
    echo "[Errno 1]: Not enough disk space" >>$VARDIR/log/mailcleaner/install_pyenv.log
    exit
fi

if [ -d .pyenv ]; then
    echo "$VARDIR/.pyenv already exists"
    if [ -d $VARDIR/.pyenv/.git ]; then
        echo "Pulling latest from Git..."
        cd $VARDIR/.pyenv
        git pull
        cd ..
    else
        echo "$VARDIR/.pyenv is not a git repository. Removing and reinstalling..."
        rm -rf $VARDIR/.pyenv
        git clone https://github.com/pyenv/pyenv.git .pyenv
    fi
else
    git clone https://github.com/pyenv/pyenv.git .pyenv
fi

export PYENV_ROOT="$VARDIR/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
pyenv install 3.12.1 -s
for i in $(pyenv versions | sed 's/* //' | awk '{ print $1 }'); do
    case "$i" in
        'system')
            ;;
        '3.12.1')
            ;;
        *)
            echo "Removing unneeded version $i"
            pyenv uninstall -f $i
            ;;
    esac
done
pyenv global 3.12.1

pip install --upgrade pip

pip install mailcleaner-library --trusted-host repository.mailcleaner.net --index https://repository.mailcleaner.net/python/ --extra-index https://pypi.org/simple/

IMPORT_MC_LIB=$(python -c "import mailcleaner")
if [ $? -eq 1 ]; then
    echo "[Errno 4]: Can't import mailcleaner" >>$VARDIR/log/mailcleaner/install_pyenv.log
    exit
fi

echo "[Errno 0]: Everything went fine..." >>$VARDIR/log/mailcleaner/install_pyenv.log
