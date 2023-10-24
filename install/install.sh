#!/bin/bash

if [ "$LOGFILE" = "" ]; then
	LOGFILE=/tmp/mailcleaner.log
fi

# Create config file if it does not exist
if [ "$CONFFILE" = "" ]; then
	CONFFILE=/etc/mailcleaner.conf
fi

if [ ! -f $CONFFILE ]; then
	HOSTNAME=$(hostname)
	cat >$CONFFILE <<EOF
SRCDIR = /usr/mailcleaner
VARDIR = /var/mailcleaner
MCHOSTNAME = $HOSTNAME
HOSTID = 1
DEFAULTDOMAIN = 
ISMASTER = Y
MYMAILCLEANERPWD = MCPassw0rd
HELONAME = $HOSTNAME
MASTERIP = 127.0.0.1
MASTERPWD = MCPassw0rd
EOF
fi

# Setup missing vars
if [ "$SRCDIR" = "" ]; then
	SRCDIR=$(grep 'SRCDIR' /etc/mailcleaner.conf | cut -d ' ' -f3)
	if [ "$SRCDIR" = "" ]; then
		SRCDIR="/usr/mailcleaner"
	fi
fi
export SRCDIR
if [ "$VARDIR" = "" ]; then
	VARDIR=$(grep 'VARDIR' /etc/mailcleaner.conf | cut -d ' ' -f3)
	if [ "$VARDIR" = "" ]; then
		VARDIR="/var/mailcleaner"
	fi
fi
export VARDIR

# Configure .bashrc
if [[ -e /root/.bashrc ]]; then
	if grep -Pq "source \${SRCDIR}/.bashrc" /root/.bashrc; then
		echo "Updating /root/.bashrc"
		mv /root/.bashrc /root/.bashrc_preexisting
	fi
fi
if [[ ! -e /root/.bashrc ]]; then
	cat >/root/.bashrc <<EOF
SRCDIR=\$(grep 'SRCDIR' /etc/mailcleaner.conf | cut -d ' ' -f3)
if [[ -z \$SRCDIR ]]; then
	SRCDIR="/usr/mailcleaner"
fi
export \$SRCDIR

# If you had a .bashrc file before installing mailcleaner, it is now sourced here
if [ -e /root/.bashrc_preexisting ]; then
	source /root/.bashrc_preexisting
fi

# Import environment from MailCleaner
source \${SRCDIR}/.bashrc
EOF
fi

# Install `docker`
if [[ "$(which docker)" == "" ]]; then
	if [[ "$(find /etc/apt/sources.list.d -name docker*)" == "" ]] || [[ "$(grep -R download.docker.com /etc/apt/sources.list.d)" == "" ]]; then
		echo "Adding Docker repository..."
		curl -fsSL https://download.docker.com/linux/debian/gpg >/etc/apt/trusted.gpg.d/docker.asc
		ARCH=$(uname -r | sed "s/^.*\-\([^\-]*\)/\1/")
		cat >/etc/apt/sources.list.d/docker.list <<EOF
    deb [arch=$ARCH] https://download.docker.com/linux/debian bookworm stable
EOF
	fi
	clear
	echo "Installing Docker..."
	apt-get update 2>&1 >/dev/null
	apt-get --assume-yes install docker-ce docker-ce-rootless-extras
fi

echo "Installing MailScanner..."
$SRCDIR/install/mailscanner/install.sh -y

###############################################
### creating users: mailcleaner, mailscanner (all others provided by packages)
if [ "$(grep 'mailcleaner' /etc/passwd)" = "" ]; then
	groupadd mailcleaner 2>&1 >>$LOGFILE
	useradd -d $VARDIR -s /bin/bash -c "MailCleaner User" -g mailcleaner mailcleaner 2>&1 >>$LOGFILE
fi
if [ "$(grep 'mailscanner' /etc/passwd)" = "" ]; then
	groupadd mailscanner 2>&1 >>$LOGFILE
	useradd -d $VARDIR -s /bin/bash -c "MailScanner" -g mailscanner mailscanner 2>&1 >>$LOGFILE
fi

###############################################
### check or create spool dirs
#echo ""
echo -n " - Checking/creating spool directories...              "
$SRCDIR/install/MC_create_vars.sh 2>&1 >>$LOGFILE
echo "[done]"

###############################################
## generate ssh keys
if [ ! -d $VARDIR/.ssh ]; then
	mkdir $VARDIR/.ssh
fi

if [ ! -e $VARDIR/.ssh/id_ed25519 ]; then
	ssh-keygen -q -t ed25519 -f $VARDIR/.ssh/id_ed25519 -N ""
	chown -R mailcleaner:mailcleaner $VARDIR/.ssh
fi

if [ "$ISMASTER" = "Y" ]; then
	MASTERHOST=127.0.0.1
	MASTERKEY=$(cat $VARDIR/.ssh/id_ed25519.pub)
fi

###############################################
### creating databases

echo -n " - Creating databases...                               "
if [ -e '/etc/mailcleaner.conf' ]; then
	MYMAILCLEANERPWD="$(grep MYMAILCLEANERPWD /etc/mailcleaner.conf | cut -d' ' -f3-)"
fi
if [ -z $MYMAILCLEANERPWD ]; then
	MYMAILCLEANERPWD=$(pwgen -1)
	echo "MYMAILCLEANERPWD = $MYMAILCLEANERPWD" >>$CONFFILE
fi
export MYMAILCLEANERPWD
$SRCDIR/install/MC_prepare_dbs.sh 2>&1 >>$LOGFILE

## recreate my_slave.cnf
#$SRCDIR/bin/dump_mysql_config.pl 2>&1 >> $LOGFILE
systemctl restart mariadb@slave 2>&1 >>$LOGFILE
echo "[done]"
sleep 5

###############################################
### install starter baysian packs
# TODO: Provide initial bayes dbs
#STPACKDIR=/root/starters
#STPACKFILE=$STPACKDIR.tar.lzma
#if [ -f $STPACKFILE ]; then
#export MYPWD=$(pwd)
#cd /root
#tar --lzma -xvf $STPACKFILE 2>&1 >>$LOGFILE
#cd $MYPWD
#fi
#if [ -d $STPACKDIR ]; then
#cp $STPACKDIR/wordlist.db $VARDIR/spool/bogofilter/database/ 2>&1 >>$LOGFILE
#chown -R mailcleaner:mailcleaner $VARDIR/spool/bogofilter/ 2>&1 >>$LOGFILE
#cp $STPACKDIR/bayes_toks $VARDIR/spool/spamassassin/ 2>&1 >>$LOGFILE
#chown -R mailcleaner:mailcleaner $VARDIR/spool/spamassassin/ 2>&1 >>$LOGFILE
#cp -a $STPACKDIR/clamspam/* $VARDIR/spool/clamspam/ 2>&1 >>$LOGFILE
#chown -R clamav:clamav $VARDIR/spool/clamspam 2>&1 >>$LOGFILE
#
#cp -a $STPACKDIR/clamd/* $VARDIR/spool/clamav/ 2>&1 >>$LOGFILE
#chown -R clamav:clamav $VARDIR/spool/clamav 2>&1 >>$LOGFILE
#fi
#echo "[done]"

## import default certificate
CERTFILE=$SRCDIR/etc/apache/certs/default.pem
KF=$(grep -n 'BEGIN RSA PRIVATE KEY' $CERTFILE | cut -d':' -f1)
KT=$(grep -n 'END RSA PRIVATE KEY' $CERTFILE | cut -d':' -f1)
CF=$(grep -n 'BEGIN CERTIFICATE' $CERTFILE | cut -d':' -f1)
CT=$(grep -n 'END CERTIFICATE' $CERTFILE | cut -d':' -f1)
KEY=$(sed -n "${KF},${KT}p;${KT}q" $CERTFILE)
CERT=$(sed -n "${CF},${CT}p;${CT}q" $CERTFILE)
QUERY="USE mc_config; UPDATE httpd_config SET tls_certificate_data='${CERT}', tls_certificate_key='${KEY}';"
echo "$QUERY" | $SRCDIR/bin/mc_mysql -m 2>&1 >>$LOGFILE

echo "update mta_config set smtp_banner='\$smtp_active_hostname ESMTP MailCleaner ($MCVERSION) \$tod_full';" | $SRCDIR/bin/mc_mysql -m mc_config 2>&1 >>$LOGFILE

###############################################
### installing mailcleaner cron job
# TODO: Create symlinks from /etc/cron.* to repo and source with those instead
echo -n " - Installing scheduled jobs...                        "
if [[ ! -d /var/spool/cron/crontabs ]]; then
	mkdir -p /var/spool/cron/crontabs
fi
ln -s $SRCDIR/scripts/cron/crontab/root /var/spool/cron/crontabs/root
ln -s $SRCDIR/scripts/cron/crontab/mailcleaner /var/spool/cron/crontabs/mailcleaner
crontab /var/spool/cron/crontabs/root 2>&1 >>$LOGFILE
/etc/init.d/cron restart 2>&1 >>$LOGFILE

echo "[done]"

###############################################
### installing `pyenv`
if [[ ! -d $VARDIR ]]; then
	mkdir $VARDIR
fi
cd $VARDIR
if [[ ! -d .pyenv ]]; then
	clear
	echo "Installing Pyenv..."
	git clone --depth=1 https://github.com/pyenv/pyenv.git .pyenv 2>/dev/null >/dev/null
	cd .pyenv
else
	cd .pyenv
	git pull --rebase origin master 2>/dev/null >/dev/null
fi
export PYENV_ROOT="$VARDIR/.pyenv"
if ! grep -q $PYENV_ROOT <<<$(echo $PATH); then
	echo "Adding $PYENV_ROOT to $PATH, but this should be included in $SRCDIR/.bashrc."
	export PATH="$PYENV_ROOT/bin:$PATH"
fi
eval "$(pyenv init --path)"
pyenv install 3.11.2 -s
pyenv local 3.11.2

clear

systemctl start mariadb@master
systemctl start mariadb@slave
echo "Installing MailCleaner Python Library..."
pip install mailcleaner-library --trusted-host repository.mailcleaner.net --index https://repository.mailcleaner.net/python/ --extra-index https://pypi.org/simple/ 2>/dev/null >/dev/null

IMPORT_MC_LIB=$(python -c "import mailcleaner")
if [ $? -eq 1 ]; then
	echo "Failed to install MailCleaner Library. Not imported."
	#exit
fi

###############################################
echo -n " - Starting..."
systemctl set-default mailcleaner.target
systemctl start mailcleaner.target
echo "[done]"

if [ ! -d $VARDIR/run ]; then
	mkdir -p $VARDIR/run
fi
touch $VARDIR/run/first-time-configuration
