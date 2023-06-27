#!/usr/bin/env bash

# Repo name, to be changed upon stable release
GHUSER="MailCleaner"
GHREPO="MailCleaner-Next"

echo "Bootstrapping MailCleaner installation"

if [ ! $(which git) ]; then
	echo -n "Installing git..."
	# Update repositories
	apt-get update 2>&1 >/dev/null
	apt-get install git 2>&1 >/dev/null
	if [ ! -x git ]; then
		echo -e "\b\b\b ✖ \nFailed to install git"
		exit
	fi
fi

echo -n "Checking MailCleaner repository..."
# Check for existing repo
if [ -d /usr/mailcleaner ]; then
	if [ ! -e /usr/mailcleaner/.git/config ]; then
		echo -e "\b\b\b ✖ \nFound '/usr/mailcleaner' which is not a git repo. Please (re)move it and run the script again"
		exit
	fi
	if ! grep -q "${GHREPO}.git" <<<$(cat /usr/mailcleaner/.git/config); then
		echo -e "\b\b\b ✖ \nFound '/usr/mailcleaner' which is not a ${GHREPO} repository. Please change target and run the script again"
		exit
	fi
# Clone instead
else
	git clone --depth 1 https://github.com/M${GHUSER}/${GHREPO}.git /usr/mailcleaner 2>&1 >/dev/null
	if [ ! -d /usr/mailcleaner ]; then
		echo -e "\b\b\b ✖ \nFailed to clone '/usr/mailcleaner' or to clone from https://github.com/MailCleaner/MailCleaner-Next.git"
		exit
	fi
fi
cd /usr/mailcleaner

# Update repo
git pull --rebase origin master 2>/dev/null >/dev/null
if [ $! ]; then
	echo -e "\b\b\b ✖ Error pulling latest commits"
	exit
else
	echo -e "\b\b\b ✔ "
fi

# Requires non-free for SNMP definitions

# Check for non-free
echo -n "Checking non-free repo  "

# Monolithic sources.list
if grep -Pq '^deb http.*debian ' <<<$(cat /etc/apt/sources.list 2>/dev/null); then
	if grep -q 'deb http.* non-free non-free-firmware' <<<$(cat /etc/apt/sources.list 2>/dev/null); then
		echo -e "\b\b\b ✔ "
	else
		echo -ne "\rMailCleaner requires the Debian 'non-free' repository to function. Do you consent to enabling this repo? [y/N]: "
		read YN
		if [[ "$YN" == "y" ]] || [[ "$YN" == "Y" ]]; then
			sed -i 's/main.*/main contrib non-free non-free-firmware/' /etc/apt/sources.list
			echo "Checking non-free repo ✔ "
		else
			echo "Aborting..."
			exit
		fi
	fi
# Individual .list files
elif grep -q 'deb http.* debian main' <<<$(cat /etc/apt/sources.list.d/*.list 2>/dev/null); then
	if grep -q 'deb http.* debian main .*non\-free' <<<$(cat /etc/apt/sources.list.d/*.list 2>/dev/null); then
		echo -e "\b\b\b ✔ "
	else
		for i in $(find /etc/apt/sources.list.d/ -name *.list -print); do
			if grep -q 'deb http.* debian ' <<<$(cat $i); then
				echo -ne "\rMailCleaner requires the Debian 'non-free' repository to function. Do you consent to enabling this repo? [y/N]: "
				read YN
				if [[ "$YN" == "y" ]] || [[ "$YN" == "Y" ]]; then
					sed -i 's/main.*/main contrib non-free non-free-firmware/' $i
					echo "Checking non-free repo ✔ "
					break
				else
					echo "Aborting..."
					exit
				fi
			fi
		done
	fi
# Newer .sources files
elif grep -q 'Components' <<<$(cat /etc/apt/sources.list.d/*.sources 2>/dev/null); then
	if grep -q 'Components.* non-free non-free-firmware' <<<$(cat /etc/apt/sources.list.d/*.sources 2>/dev/null); then
		echo -e "\b\b\b ✔ "
	else
		for i in $(find /etc/apt/sources.list.d/ -name *.sources -print); do
			if [ -z $YN ]; then
				echo -ne "\rMailCleaner requires the Debian 'non-free' repository to function. Do you consent to enabling this repo? [y/N]: "
				read YN
			fi
			if [[ "$YN" == "y" ]] || [[ "$YN" == "Y" ]]; then
				sed -i 's/main.*/main contrib non-free non-free-firmware/' $i
				echo "Checking non-free repo ✔ "
				break
			else
				echo "Aborting..."
				exit
			fi
		done
	fi
fi

# Clear cache
echo -n "Clearing APT cache..."
rm /var/lib/apt/lists/* 2>/dev/null
echo -e "\b\b\b ✔ "

# Update repositories
echo -n "Updating APT repos..."
apt-get update 2>&1 >/dev/null
echo -e "\b\b\b ✔ "

DPKG=$(dpkg -l)
FAILED=""
echo "Checking/Installing APT repos..."
for i in $(cat debian-bootstrap/required.apt); do
	if grep -qP "^ii  $i" <<<$DPKG; then
		echo -e "  Checking $i ✔  "
	else
		echo -ne "\r  Installing $i..."
		apt-get --assume-yes install $i 2>&1 >/dev/null

		DPKG=$(dpkg -l)
		if grep -qP "^ii  $i" <<<$DPKG; then
			echo -e "\b\b\b ✔ "
		else
			echo -e "\b\b\b ✖ "
			FAILED="$FAILED
$i"
		fi
	fi
done

if [[ $FAILED != "" ]]; then
	echo "Installing APT dependencies ✖"
	echo -e "These packages failed to install:\n$FAILED"
	echo "You can try to fix by running \`apt-get install -f\` then running this script again"
	exit
fi
echo "Installing APT dependencies ✔"

echo "TODO..."
