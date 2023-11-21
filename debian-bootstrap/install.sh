#!/usr/bin/env bash

GHUSER="MailCleaner"

# Repo name, to be changed upon Stable release
GHREPO="MailCleaner-Next"
#GHREPO="MailCleaner"

# Git/HTTP protocol, to be changed upon repo going public
#GHHOST="git@github.com:"
GHHOST="https://github.com"

# Current checksum of this script, to compare after `git pull`
CURRENT=$(md5sum $0)

# Errors which must be resolved before success, but don't justify killing the script in action
ERRORS=''

echo "Bootstrapping MailCleaner installation"

DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install console-data 2>/dev/null >/dev/null
if [[ -e "/etc/default/console-setup" ]]; then
	echo -n "Configuring console..."
	sed -i 's/FONTFACE=".*/FONTFACE="Terminus"/' /etc/default/console-setup
	sed -i 's/FONTSIZE=".*/FONTSIZE="24x12"/' /etc/default/console-setup
	systemctl restart console-setup
	if [ $! ]; then
		echo -e "\b\b\b x "
	else
		echo -e "\b\b\b * "
	fi
fi

# Check for non-free
echo -n "Checking non-free repo..."

# Monolithic sources.list
if grep -Pq '^deb http.*debian/? ' <<<$(cat /etc/apt/sources.list 2>/dev/null); then
	if grep -q 'deb http.* non-free non-free-firmware' <<<$(cat /etc/apt/sources.list 2>/dev/null); then
		echo -e "\b\b\b * "
	else
		echo -ne "\rMailCleaner requires the Debian 'non-free' repository to function. Do you consent to enabling this repo? [y/N]: "
		read YN
		if [[ "$YN" == "y" ]] || [[ "$YN" == "Y" ]]; then
			sed -i 's/main.*/main contrib non-free non-free-firmware/' /etc/apt/sources.list
			echo -e "\r Checking non-free repo * \n"
		else
			echo "Aborting..."
			exit
		fi
	fi
# Individual .list files
elif grep -q 'deb http.* debian main' <<<$(cat /etc/apt/sources.list.d/*.list 2>/dev/null); then
	if grep -q 'deb http.* debian main .*non\-free' <<<$(cat /etc/apt/sources.list.d/*.list 2>/dev/null); then
		echo -e "\b\b\b * "
	else
		for i in $(find /etc/apt/sources.list.d/ -name *.list -print); do
			if grep -q 'deb http.* debian ' <<<$(cat $i); then
				echo -ne "\rMailCleaner requires the Debian 'non-free' repository to function. Do you consent to enabling this repo? [y/N]: "
				read YN
				if [[ "$YN" == "y" ]] || [[ "$YN" == "Y" ]]; then
					sed -i 's/main.*/main contrib non-free non-free-firmware/' $i
					echo -e "\r Checking non-free repo * \n"
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
		echo -e "\b\b\b * "
	else
		echo -ne "\rMailCleaner requires the Debian 'non-free' repository to function. Do you consent to enabling this repo? [y/N]: "
		read YN
		for i in $(find /etc/apt/sources.list.d/ -name *.sources -print); do
			if [ -z $YN ]; then
				echo -ne "\rMailCleaner requires the Debian 'non-free' repository to function. Do you consent to enabling this repo? [y/N]: "
				read YN
			fi
			if [[ "$YN" == "y" ]] || [[ "$YN" == "Y" ]]; then
				sed -i 's/main.*/main contrib non-free non-free-firmware/' $i
				echo -e "\r Checking non-free repo * \n"
				break
			else
				echo "Aborting..."
				exit
			fi
		done
	fi
else
	echo -e "\bx \nNo known APT sources files were found"
	exit
fi

# MailCleaner repository
if [ ! -e /etc/apt/keyrings/mailcleaner.gpg ]; then
	cp /usr/mailcleaner/etc/mailcleaner/mailcleaner.asc /etc/apt/trusted.gpg.d/mailcleaner.asc
	cat /etc/apt/trusted.gpg.d/mailcleaner.asc | gpg --yes --dearmor -o /etc/apt/keyrings/mailcleaner.gpg
	echo 'deb [signed-by=/etc/apt/keyrings/mailcleaner.gpg] https://cdnmcpool.mailcleaner.net bookworm main' >/etc/apt/sources.list.d/mailcleaner.list
fi

# Docker repository
if [ ! -e /etc/apt/keyrings/docker.gpg ]; then
	wget -q -O /etc/apt/trusted.gpg.d/docker.asc https://download.docker.com/linux/debian/gpg
	cat /etc/apt/trusted.gpg.d/docker.asc | gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
	echo 'deb [signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable' >/etc/apt/sources.list.d/docker.list
fi

# DCC repository
if [ ! -e /etc/apt/keyrings/obs-home-voegelas.gpg ]; then
	wget -q -O /etc/apt/trusted.gpg.d/obs-home-voegelas.asc https://download.opensuse.org/repositories/home:/voegelas/Debian_12/Release.key
	cat /etc/apt/trusted.gpg.d/obs-home-voegelas.asc | gpg --yes --dearmor -o /etc/apt/keyrings/obs-home-voegelas.gpg
fi
if [ ! -e /etc/apt/sources.list.d/obs-voegelas.list ]; then
	echo 'deb [signed-by=/etc/apt/keyrings/obs-home-voegelas.gpg] https://download.opensuse.org/repositories/home:/voegelas/Debian_12/ ./' | tee /etc/apt/sources.list.d/obs-voegelas.list
fi

# Clear cache
echo -n "Clearing APT cache..."
rm /var/lib/apt/lists/* 2>/dev/null
if [ $! ]; then
	echo -e "\b\b\b x "
else
	echo -e "\b\b\b * "
fi

# Update repositories
echo -n "Updating APT repos..."
apt-get update 2>&1 >/dev/null
if [ $! ]; then
	echo -e "\b\b\b x "
else
	echo -e "\b\b\b * "
fi

DPKG=$(dpkg -l)
FAILED=""
echo "Checking/Installing APT repos..."
for i in $(cat debian-bootstrap/required.apt); do
	if grep -qP "^ii  $i" <<<$DPKG; then
		echo -e "  Checking $i *  "
	else
		echo -ne "\r  Installing $i..."
		DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install $i 2>/dev/null >/dev/null

		DPKG=$(dpkg -l)
		if grep -qP "^ii  $i" <<<$DPKG; then
			echo -e "\b\b\b * "
		else
			echo -e "\b\b\b x "
			FAILED="$FAILED
    $i"
		fi
	fi
done

if [[ $FAILED != "" ]]; then
	echo "Installing APT dependencies..."
	ERRORS="${ERRORS}
x These packages failed to install:
  $FAILED
  You can try to fix by running \`apt-get install -f\` then running this script again"
fi

# Check for existing repo
echo -n "Checking MailCleaner repository..."
if [ -d /usr/mailcleaner ]; then
	if [ ! -e /usr/mailcleaner/.git/config ]; then
		echo -e "\b\b\b x \nFound '/usr/mailcleaner' which is not a git repo. Please (re)move it and run the script again"
		exit
	fi
	if ! grep -q "${GHREPO}.git" <<<$(cat /usr/mailcleaner/.git/config); then
		echo -e "\b\b\b x \nFound '/usr/mailcleaner' which is not a ${GHREPO} repository. Please change target and run the script again"
		exit
	fi
# Clone instead
else
	git clone --depth 1 ${GHHOST}/${GHUSER}/${GHREPO}.git /usr/mailcleaner 2>&1 >/dev/null
	if [ ! -d /usr/mailcleaner ]; then
		echo -e "\b\b\b x \nFailed to clone '/usr/mailcleaner' or to clone from https://github.com/MailCleaner/MailCleaner-Next.git"
		exit
	fi
fi

# Update repo
cd /usr/mailcleaner
git pull --rebase origin master 2>/dev/null >/dev/null
if [ $! ]; then
	echo -e "\b\b\b x Error pulling latest commits"
	exit
else
	echo -e "\b\b\b * "
	if [[ $CURRENT != $(md5sum $0) ]]; then
		echo "$0 has changed. Please run the command again to ensure that you have the latest installation procedures"
		exit
	fi
fi

echo "Cleaning up..."
echo -n "Removing unnecessary APT packages..."
apt-get autoremove --assume-yes 2>/dev/null >/dev/null
if [ $! ]; then
	echo -e "\b\b\b x "
else
	echo -e "\b\b\b * "
fi
echo -n "Cleaning APT archive..."
apt-get clean --assume-yes 2>/dev/null >/dev/null
if [ $! ]; then
	echo -e "\b\b\b x "
else
	echo -e "\b\b\b * "
fi

clear
if [ $! ]; then
	echo -e "\b\b\b x "
	ERRORS="${ERRORS}
x Failed running /usr/mailcleaner/install/install.sh"
fi

clear
if [[ $ERRORS != "" ]]; then
	echo "Finished with errors:"
	echo $ERRORS
	echo "Please try to remedy these errors, report them as needed, then run this script again to verify that there are no remaining errors with the installation."
fi
echo "Creating bare mailcleaner configuration file..."
touch /etc/mailcleaner.conf
echo "Bootstrapping complete, starting main MailCleaner Installation Wizard. Please follow all steps..."
/usr/mailcleaner/scripts/installer/installer.pl
