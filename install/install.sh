#!/bin/bash

if [ -z "$LOGFILE" ]; then
    LOGFILE=/tmp/mailcleaner.log
fi

# Create config file if it does not exist
if [ -z "$CONFFILE" ]; then
    CONFFILE=/etc/mailcleaner.conf
fi

if [ ! -f $CONFFILE ]; then
    MCHOSTNAME=$(hostname)
    cat >$CONFFILE <<EOF
SRCDIR = /usr/mailcleaner
VARDIR = /var/mailcleaner
MCHOSTNAME = $MCHOSTNAME
HOSTID = 1
DEFAULTDOMAIN = 
ISMASTER = Y
MYMAILCLEANERPWD = MCPassw0rd
HELONAME = $MCHOSTNAME
MASTERIP = 127.0.0.1
MASTERPWD = MCPassw0rd
EOF
fi

# Setup missing vars
if [ -z $SRCDIR ]; then
    SRCDIR=$(grep 'SRCDIR' /etc/mailcleaner.conf | cut -d ' ' -f3)
    if [[ "$SRCDIR" == "" ]]; then
        SRCDIR="/usr/mailcleaner"
        echo "SRCDIR = $SRCDIR" >>$CONFFILE
    fi
fi
export SRCDIR
if [ -z $VARDIR ]; then
    VARDIR=$(grep 'VARDIR' /etc/mailcleaner.conf | cut -d ' ' -f3)
    if [[ "$VARDIR" == "" ]]; then
        VARDIR="/var/mailcleaner"
        echo "VARDIR = $VARDIR" >>$CONFFILE
    fi
fi
export VARDIR

if [ -z "$MYMAILCLEANERPWD" ]; then
    MYMAILCLEANERPWD="$(grep MYMAILCLEANERPWD /etc/mailcleaner.conf | cut -d' ' -f3-)"
    if [[ "$MYMAILCLEANERPWD" == "" ]]; then
        MYMAILCLEANERPWD=$(pwgen -1)
        echo "MYMAILCLEANERPWD = $MYMAILCLEANERPWD" >>$CONFFILE
    fi
fi
export MYMAILCLEANERPWD
export MYROOTPWD=$MYMAILCLEANERPWD
if [ -z "$WEBADMINPWD" ]; then
    WEBADMINPWD=$MYMAILCLEANERWPD
fi
export WEBADMINPWD
if [ -z "$HOSTID" ]; then
    HOSTID=1
fi
export HOSTID
if [ -z "$CLIENTID" ]; then
    CLIENTID=0
fi
export CLIENTID
if [ -z "$ORGANIZATION" ]; then
    ORGANIZATION="Anonymous"
fi
export ORGANIZATION
if [ -z "$MCHOSTNAME" ]; then
    MCHOSTNAME=$(hostname)
fi
export MCHOSTNAME
if [ -z "$DEFAULTDOMAIN" ]; then
    DEFAULTDOMAIN=''
fi
export DEFAULTDOMAIN
if [ -z "$CLIENTTECHMAIL" ]; then
    if [[ "$DEFAULTDOMAIN" -ne "" ]]; then
        CLIENTTECHMAIL="postmaster@$DEFAULTDOMAIN"
    else
        CLIENTTECHMAIL='root@localhost'
    fi
fi
export CLIENTTECHMAIL

# Configure .bashrc
if [[ -e /root/.bashrc ]]; then
    if ! grep -q 'source ${SRCDIR}/.bashrc' <<< $(cat /root/.bashrc); then
        echo "Updating /root/.bashrc"
        mv /root/.bashrc /root/.bashrc_preexisting
    fi
fi
if [[ ! -e /root/.bashrc ]]; then
    cat >/root/.bashrc <<EOF
# If you had a .bashrc file before installing mailcleaner, it is now sourced here
if [ -e /root/.bashrc_preexisting ]; then
    source /root/.bashrc_preexisting
fi

SRCDIR=\$(grep 'SRCDIR' /etc/mailcleaner.conf | cut -d ' ' -f3)
if [[ -z \$SRCDIR ]]; then
    SRCDIR="/usr/mailcleaner"
fi
export SRCDIR

# Import environment from MailCleaner
source \${SRCDIR}/.bashrc
EOF

    cat >/root/.profile <<EOF
# Import from .bashrc
source /root/.bashrc
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
    echo "Installing Docker..."
    apt-get update 2>&1 >/dev/null
    apt-get --assume-yes install docker-ce docker-ce-rootless-extras
fi

###############################################
### create MailCleaner user/group
EXISTINGUSER=$(id -u mailcleaner 2>/dev/null)
EXISTINGGROUP=$(id -g mailcleaner 2>/dev/null)
if ! [[ $EXISTINGUSER =~ ^[0-9]+$ ]]; then
    echo "Creating mailcleaner user and group..."
    useradd -d $VARDIR -s /bin/bash -c "MailCleaner" -U mailcleaner 2>&1 >>$LOGFILE
elif ! [[ $EXISTINGGROUP =~ ^[0-9]+$ ]]; then
    echo "Creating mailcleaner group..."
    groupadd -U mailcleaner mailcleaner 2>&1 >>$LOGFILE
fi

###############################################
### configure SystemD serivices
echo "Installing SystemD unit files..."
$SRCDIR/install/systemd.sh -f 2>&1 >>$LOGFILE
systemctl daemon-reload

###############################################
### check or create spool dirs
echo "Checking/creating spool directories...              "
$SRCDIR/install/MC_create_vars.sh 2>&1 >>$LOGFILE

###############################################
## generate ssh keys
if [ ! -d $VARDIR/.ssh ]; then
    mkdir $VARDIR/.ssh
fi

if [ ! -e $VARDIR/.ssh/id_ed25519 ]; then
    ssh-keygen -q -t ed25519 -f $VARDIR/.ssh/id_ed25519 -N ""
    chown -R mailcleaner:mailcleaner $VARDIR/.ssh
fi
export HOSTKEY=$(cat $VARDIR/.ssh/id_ed25519.pub)

if [ -z $ISMASTER ]; then
    ISMASTER="Y"
fi
export ISMASTER
if [[ "$ISMASTER" -eq "Y" ]]; then
    MASTERHOST=127.0.0.1
    MASTERKEY=$(cat $VARDIR/.ssh/id_ed25519.pub)
    MASTERPASSWD=$MYMAILCLEANERPWD
else
    if [ -z $MASTERHOST ]; then
        echo "Missing MASTERHOST for slave node"
        exit
    fi
    if [ -z $MASTERKEY ]; then
        echo "Missing MASTERKEY for slave node"
        exit
    fi
    if [ -z $MASTERPASSWD ]; then
        echo "Missing MASTERPASSWD for slave node"
        exit
    fi
fi
export MASTERHOST
export MASTERKEY
export MASTERPASSWD

###############################################
### creating databases

echo "Configuring databases..."
systemctl stop mariadb
systemctl disable mariadb
systemctl start mariadb@master
sleep 1
DBEXISTS=$(echo 'SELECT * FROM system_conf;' | mc_mysql -m mc_config 2>/dev/null)
if [ -n $FORCEDBREINSTALL ]; then
    echo "Forcing reinstallation of databases..."
    unset DBEXISTS
fi
if [ -z "$DBEXISTS" ]; then
    echo "Creating databases..."
    $SRCDIR/install/MC_prepare_dbs.sh 2>&1 >>$LOGFILE
    systemctl restart mariadb@slave 2>&1 >>$LOGFILE
fi

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
KEYFILE=$SRCDIR/etc/apache/certs/default.key
if [ ! -e $KEYFILE ]; then
    echo Generating self-signing key
    openssl genpkey -algorithm ED25519 -out $KEYFILE 2>&1 >$LOGFILE
fi
CERTFILE=$SRCDIR/etc/apache/certs/default.crt
if [ ! -e $CERTFILE ]; then
    echo Generating self-signed certificate for HTTPS/STARTTLS
    cp $SRCDIR/etc/apache/default.conf_template /tmp/default.conf
    sed -i "s/__HOSTNAME__/$MCHOSTNAME/" /tmp/default.conf
    sed -i "s/__CLIENTTECHMAIL__/$CLIENTTECHMAIL/" /tmp/default.conf
    sed -i "s/__ORGANIZATION__/$ORGANIZATION/" /tmp/default.conf
    openssl req -new -out /tmp/default.csr -key $KEYFILE -config /tmp/default.conf 2>&1 >$LOGFILE
    openssl x509 -req -days 3650 -in /tmp/default.csr -signkey $KEYFILE -out $CERTFILE 2>&1 >$LOGFILE
fi
KEY=$(cat $KEYFILE)
CERT=$(cat $CERTFILE)
QUERY="USE mc_config; UPDATE httpd_config SET tls_certificate_data='${CERT}', tls_certificate_key='${KEY}', tls_certificate_chain='';"
echo "$QUERY" | $SRCDIR/bin/mc_mysql -m 2>&1 >>$LOGFILE
QUERY="USE mc_config; UPDATE mta_config SET tls_certificate_data='${CERT}', tls_certificate_key='${KEY}';"
echo "$QUERY" | $SRCDIR/bin/mc_mysql -m 2>&1 >>$LOGFILE

#echo "update mta_config set smtp_banner='\$smtp_active_hostname ESMTP MailCleaner ($MCVERSION) \$tod_full';" | $SRCDIR/bin/mc_mysql -m mc_config 2>&1 >>$LOGFILE

###############################################
### installing mailcleaner cron job
echo "Installing scheduled jobs..."
if [[ ! -d /var/spool/cron/crontabs ]]; then
    mkdir -p /var/spool/cron/crontabs
fi
if [[ ! -e /var/spool/cron/crontabs/root ]]; then
    ln -s $SRCDIR/scripts/cron/crontab/root /var/spool/cron/crontabs/root
    crontab /var/spool/cron/crontabs/root 2>&1 >>$LOGFILE
fi
if [[ ! -e /var/spool/cron/crontabs/mailcleaner ]]; then
    ln -s $SRCDIR/scripts/cron/crontab/mailcleaner /var/spool/cron/crontabs/mailcleaner
fi
/etc/init.d/cron restart 2>&1 >>$LOGFILE

###############################################
### installing `pyenv`
if [[ ! -d $VARDIR ]]; then
    mkdir $VARDIR
fi
cd $VARDIR
if [[ ! -d .pyenv ]]; then
    echo "Installing Pyenv..."
    git clone --depth=1 https://github.com/pyenv/pyenv.git .pyenv 2>&1 >$LOGFILE
    cd .pyenv
else
    cd .pyenv
    git pull --rebase origin master 2>&1 >$LOGFILE
fi
export PYENV_ROOT="$VARDIR/.pyenv"
if ! grep -q $PYENV_ROOT <<<$(echo $PATH); then
    echo "Adding $PYENV_ROOT to $PATH, but this should be included in $SRCDIR/.bashrc."
    export PATH="$PYENV_ROOT/bin:$PATH"
fi
eval "$(pyenv init --path)"
pyenv install 3.11.2 -s 2>&1 >$LOGFILE
pyenv local 3.11.2 2>&1 >$LOGFILE

echo "Installing MailCleaner Python Library..."
pip install mailcleaner-library --trusted-host repository.mailcleaner.net --index https://repository.mailcleaner.net/python/ --extra-index https://pypi.org/simple/ 2>&1 >$LOGFILE

IMPORT_MC_LIB=$(python -c "import mailcleaner")
if [ $? -eq 1 ]; then
    echo "Failed to install MailCleaner Library. Not imported."
    #exit
fi

# ClamAV sigs
if [[ ! -e $SRCDIR/etc/clamav/freshclam.conf ]]; then
    $SRCDIR/bin/dump_clamav_config.pl
fi
$SRCDIR/scripts/cron/update_antivirus.sh

###############################################
echo -n "Setting MailCleaner as default SystemD target..."
rm /etc/systemd/system/default.target
rm /lib/systemd/system/default.target
ln -s /usr/mailcleaner/scripts/systemd/mailcleaner.target /lib/systemd/system/default.target
if [ $! ]; then
    echo -e "\b\b\b x "
    ERRORS="${ERRORS}
x Failed to symlink mailcleaner.target to /lib/systemd/system/default.target"
fi

echo "Starting..."
systemctl start mailcleaner.target

for i in $($SRCDIR/bin/get_status.pl -s | tr '|' ' '); do
    if [ $i ]; then
        echo "Not all services started successfully. Please review $LOGFILE and run installation again when problems are resolved."
        $SRCDIR/bin/get_status.pl -s -v
        exit 255
    fi
done
touch $VARDIR/run/first-time-configuration
echo "Success!"
