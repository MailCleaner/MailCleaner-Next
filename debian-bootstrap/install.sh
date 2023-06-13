#!/usr/bin/env bash

echo "Bootstrapping MailCleaner installation..."

echo -n "Checking MailCleaner repository..."

if [ ! $(which git) ]; then
    echo "Installing git..."
    # Update repositories
    apt-get update 2>&1 >/dev/null
    apt-get install git 2>&1 >/dev/null
    if [ ! -x git ]; then
	echo -e "\b\b\b ✖ \nFailed to install git"
	exit
    fi
fi

if [ ! -d /usr/mailcleaner ]; then
    if [ -e .git/config ]; then
	if grep -q 'MailCleaner-Next.git' <<< `cat .git/config`; then
	    PWD=pwd
	    cd /root
	    mv $PWD /usr/mailcleaner
	fi
    else
	git clone --depth 1 https://github.com/MailCleaner/MailCleaner-Next.git /usr/mailcleaner 2>&1 >/dev/null
    fi
fi
if [ ! -d /usr/mailcleaner ]; then
    echo -e "\b\b\b ✖ \nFailed to locate existing MailCleaner repository '/usr/mailcleaner' or to clone from https://github.com/MailCleaner/MailCleaner-Next.git"
    exit
fi

cd /usr/mailcleaner
git pull --rebase origin master 2>/dev/null >/dev/null
if [ $! ]; then
    echo -e "\b\b\b ✖ Error pulling latest commits"
    exit
else
    echo -e "\b\b\b ✔ "
fi

echo -n "Checking for non-free repository..."

# Check for non-free
if grep -Pq '^deb http.*debian ' <<<`cat /etc/apt/sources.list 2>/dev/null`; then
    if grep -q 'deb http.* non-free non-free-firmware' <<<`cat /etc/apt/sources.list 2>/dev/null`; then
        ::
    else
	sed -i 's/main.*/main contrib non-free non-free-firmware/' /etc/apt/sources.list
    fi
elif grep -q 'deb http.* debian ' <<<`cat /etc/apt/sources.list.d/*.list 2>/dev/null`; then
    for i in `find /etc/apt/sources.list.d/ -name *.list -print`; do
	if grep -q 'deb http.* debian ' <<<`cat $i`; then
	    sed -i 's/main.*/main contrib non-free non-free-firmware/' $i
	    break
	fi
    done
elif grep -q 'Components.* non-free non-free-firmware' <<<`cat /etc/apt/sources.list.d/*.sources 2>/dev/null`; then
    for i in `find /etc/apt/sources.list.d/ -name *.sources -print`; do
	sed -i 's/main.*/main contrib non-free non-free-firmware/' $i
    done
fi
echo -e "\b\b\b ✔ "
    
echo "Installing APT dependencies..."

# Clear cache
echo clearing cache
rm /var/lib/apt/lists/* 2>/dev/null

# Update repositories
echo updating repos
apt-get update 2>&1 >/dev/null

echo DEBUG fetching list
DPKG=`dpkg -l`
FAILED=""
echo DEBUG looping
for i in `cat debian-bootstrap/required.apt`; do
    if grep -qP "^ii  $i" <<<$DPKG; then
	echo -e "  $i ✔  "
    else
	echo -n "  $i ..."
	apt-get --assume-yes install $i 2>/dev/null

	if [ $! ]; then
	    echo -e "\r  $i ✖  "
	    FAILED="$FAILED
$i"
	else
	    echo -e "\r  $i ✔  "
	fi
    fi
done
if [[ $FAILED -eq "" ]]; then
    echo "Installing APT dependencies ✖"
    echo -e "These packages failed to install:\n$FAILED"
    echo "You can try to fix by running \`apt-get install -f\` then running this script again"
    exit
fi
echo "Installing APT dependencies ✔"
	    

