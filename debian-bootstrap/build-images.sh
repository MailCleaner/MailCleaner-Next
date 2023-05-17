#!/bin/bash

################################################################################
# Usage information
################################################################################

function usage() {
	echo "Usage: $0 [-ih] [-ncd local_args] [-lktfpa debian-preseed-args]"
	echo ""
	echo "-i    Interactive Mode (default: false)"
	echo "    All other arguments will pre-seed defaults, but will be confirmed. If you already have a Debian"
	echo "    preseed file from a previous run (.debian-preseed.txt), you can use it again. Unless enabled,"
	echo "    the default behaviour is silent and will use a .debian-preseed.txt file if it already exists,"
	echo "    otherwise it will use all arguments provided at the commandline and the remaining defaults."
	echo ""
	echo "-h    Help. (default: undefined)"
	echo "    This informaton. All other options will be ignored."
	echo ""
	echo "LOCAL ARGUMENTS"
	echo ""
	echo "Several arguments apply to actions performed directly by this script:"
	echo ""
	echo "-n    Name (default: mailcleaner)"
	echo "    Base name for image. If multiple are given, multiple copies will be created, but this will"
	echo "    conflict with -c. If only one is given and -c is also used, they will be numbered with a two-"
	echo "    digit suffix. eg. '-n mc -c 3' will create 'mc00' 'mc01' and 'mc02'"
	echo ""
	echo "-c    Count (default: undefined)"
	echo "    Number of images to create. See previous. When undefined, no suffix will be added"
	echo ""
	echo "-d    Debug Mode. (default: false)"
	echo "    Provides (more) verbose output. No output for non-interactive mode unless enabled"
	echo ""
	echo "DEBIAN PRESEED ARGUMENTS"
	echo ""
	echo "Other arguments will be written to the .debian-preseed.txt file which is then used to generating the"
	echo "image using system tools:"
	echo ""
	echo "-l    Locale (default: en_US)"
	echo "    Localization"
	echo ""
	echo "-k    Keyboard (default: us)"
	echo "    Keyboard layout"
	echo ""
	echo "-t    Timezone (default: UTC)"
	echo "    \$TZ format. See /usr/share/zoneinfo/ on another Debian machine. eg. America/New_York"
	echo ""
	echo "-f    Disable non-free (default: undefined)"
	echo "    Disable the use of non-free (proprietary) firmware. No argument value required"
	echo ""
	echo "-e    Disable EFI (default: false)"
	echo "    Disable support for EFI bootloader. Exclude to leave EFI enabled"
	echo ""
	echo "-p    Root Password (default: MCPassw0rd)"
	echo "    Set a different root password. If no argument is provided, then password access will be"
	echo "    disabled. You will only have access using SSH as discussed next"
	echo ""
	echo "-a    Authorized keys url (default: undefined)"
	echo "    HTTP(S) url to an 'authorized_keys' ssh file. If provided, password-based SSH authentication for"
	echo "    the root user will be removed (recommended)."
}

################################################################################
# Parse arguments
################################################################################

NAMES=()
BUFFER=''
NONFREE='true'
DEBUG=0
for i in ${@}; do
	if [[ $BUFFER != '' ]] && [ $(echo $i | cut -c1) != '-' ]; then
		if [[ $BUFFER == 'NAME' ]]; then
			#TODO Push to list instead
			NAMES+=($i)
		elif [[ $BUFFER == 'COUNT' ]]; then
			COUNT=$i
			BUFFER=''
		elif [[ $BUFFER == 'LOCALE' ]]; then
			LOCALE=$i
			BUFFER=''
		elif [[ $BUFFER == 'KEYBOARD' ]]; then
			KEYBOARD=$i
			BUFFER=''
		elif [[ $BUFFER == 'TIMEZONE' ]]; then
			TIMEZONE=$i
			BUFFER=''
		elif [[ $BUFFER == 'PASSWORD' ]]; then
			PASSWORD=$i
			BUFFER=''
		elif [[ $BUFFER == 'AUTHORIZEDKEYS' ]]; then
			AUTHORIZEDKEYS=$i
			BUFFER=''
		fi
	else
		if [[ $BUFFER != '' ]]; then
			BUFFER=''
		fi
		if [[ $i == '-d' ]]; then
			if [[ $DEBUG == 1 ]]; then
				echo "ERROR: Please provide -d option only once"
				exit
			fi
			DEBUG=1
		elif [[ $i == '-e' ]]; then
			if [ ! -z $EFI ]; then
				echo "ERROR: Please provide -e option only once"
				exit
			fi
			EFI='N'
		elif [[ $i == '-h' ]]; then
			usage
			exit
		elif [[ $i == '-f' ]]; then
			if [[ $NONFREE == 'false' ]]; then
				echo "ERROR: Please provide -f option only once"
				exit
			fi
			NONFREE='false'
		elif [[ $i == '-i' ]]; then
			if [ ! -z $INTERACTIVE ]; then
				echo "ERROR: Please provide -f option only once"
				exit
			fi
			INTERACTIVE=1
		elif [[ $i == '-n' ]]; then
			if [[ ${#NAMES[@]} -gt 0 ]]; then
				echo "ERROR: Please provide all names on one sequence"
				exit
			fi
			BUFFER='NAME'
		elif [[ $i == '-c' ]]; then
			if [ ! -z $COUNT ]; then
				echo "ERROR: Please provide -c option only once"
				exit
			fi
			BUFFER='COUNT'
		elif [[ $i == '-l' ]]; then
			if [ ! -z $LOCALE ]; then
				echo "ERROR: Please provide -l option only once"
				exit
			fi
			BUFFER='LOCALE'
		elif [[ $i == '-k' ]]; then
			if [ ! -z $KEYBOARD ]; then
				echo "ERROR: Please provide -k option only once"
				exit
			fi
			BUFFER='KEYBOARD'
		elif [[ $i == '-t' ]]; then
			if [ ! -z $TIMEZONE ]; then
				echo "ERROR: Please provide -t option only once"
				exit
			fi
			BUFFER='TIMEZONE'
		elif [[ $i == '-p' ]]; then
			if [ ! -z $PASSWORD ]; then
				echo "ERROR: Please provide -p option only once"
				exit
			fi
			BUFFER='PASSWORD'
		elif [[ $i == '-a' ]]; then
			if [ ! -z $AUTHORIZEDKEYS ]; then
				echo "ERROR: Please provide -a option only once"
				exit
			fi
			BUFFER='AUTHORIZEDKEYS'
		else
			echo "ERROR: Unknown argument '$i'"
			exit
		fi
	fi
done

################################################################################
# Prerequisites
################################################################################

# Require sudo if not running as root
SUDO=''
if [[ $UID != 0 ]]; then
	if [[ ! $(groups | grep -P '\bsudo\b') ]]; then
		echo "ERROR: Must be run as root or as a member of the sudo group"
		exit
	fi
	SUDO='sudo '
fi

OS="UNKNOWN"
if [ -f /etc/os-release ]; then
	OS=$(grep -P '^ID=' /etc/os-release | cut -d'=' -f2 | sed 's/"//g')
	OS_VERSION=$(grep -P '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | sed 's/"//g')
else
	echo "ERROR: Unable to determine host OS"
	exit
fi

if [[ $OS != 'debian' ]]; then
	echo "ERROR: Image generation currently only works on Debian\n"
	exit
fi
if [[ $OS_VERSION != '12' ]] && [[ $DEBUG == 1 ]]; then
	echo "WARNING: Image generation currently only tested on Bookworm\n"
fi

################################################################################
# Dependencies
################################################################################

# List of necessary executables (key) with their package names (value)
declare -A DEPENDENCIES=(
	[image - factory]="image-factory"
	#[another]="package-name"
)

if [[ $DEBUG == 1 ]]; then
	echo "INFO: Checking for missing dependencies..."
fi
declare -a MISSING
for i in "${!DEPENDENCIES[@]}"; do
	if [ ! $(which $i) ]; then
		MISSING+=("$i")
	fi
done

if [[ ${#MISSING[@]} != 0 ]]; then
	INSTALL_STRING='apt-get install --assume-yes '
	if [[ $INTERACTIVE = 1 ]]; then
		echo "WARNING: Missing build requirement(s):"
		for pkg in "${MISSING[@]}"; do
			INSTALL_STRING=" $INSTALL_STRING ${DEPENDENCIES[$pkg]}"
			printf "$pkg "
		done
		echo -e "\nWARNING: Attempting to install. Force quit with Ctrl+C if you would like to stop."
		n=10
		while [[ $n -gt 0 ]]; do
			printf "\r${n}..."
			let n=(n - 1)
			sleep 1
		done
		printf "\rInstalling...\n"
	fi
	if [[ $DEBUG == 1 ]]; then
		$SUDO apt-get update
		$SUDO $INSTALL_STRING
	else
		$SUDO apt-get update >/dev/null 2>&1
		$SUDO $INSTALL_STRING >/dev/null 2>&1
	fi
fi
unset DEPENDENCIES

for i in "${MISSING[@]}"; do
	if [ ! $(which $i) ]; then
		echo "ERROR: One or more dependencies failed to install. Run in debug mode '-d' for apt logs."
		exit
	fi
done
unset MISSING

if [[ $DEBUG == 1 ]]; then
	echo "INFO: All dependencies satisfied"
fi

################################################################################
# Interactive
################################################################################

REGENERATE='Y'
if [ -e '.debian-preseed.txt' ]; then
	if [ ! -z $INTERACTIVE ]; then
		echo "Preseed file already exists. Use the same settings as last time? Additional Debian preseed arguments"
		echo "will be ignored. [Y/n]"
		read -n1 REGENERATE
		echo ""
		while [[ $REGENERATE != 'n' ]] && [[ $REGENERATE != 'N' ]] && [[ $REGENERATE != 'y' ]] && [[ $REGENERATE != 'Y' ]]; do
			echo "Invalid selection [Y/n]"
			read -n1 REGENERATE
			echo ""
		done
	elif [ -z $LOCALE ] && [ -z $KEYBOARD ] && [ -z $TIMEZONE ] && [[ $NONFREE == 'true' ]] && [ -z $PASSWORD ] && [ -z $AUTHORIZEDKEYS ]; then
		REGENERATE='N'
	fi
fi

if [ ! -z $INTERACTIVE ]; then
	FALLBACK=1
	if [ ! -z $COUNT ]; then
		FALLBACK=$COUNT
	fi
	echo "How many hosts would you like to create? ($FALLBACK)"
	read C
	if [[ $C == '' ]]; then
		C=$FALLBACK
	fi
	while [ ! -z $C ]; do
		if $(grep -qP '^[0-9]$' <<<$(echo $C)); then
			COUNT=$C
			unset C
		else
			echo "Invalid selection (please select a number)"
			read C
		fi
	done
	if [[ $COUNT -gt 1 ]]; then
		echo "Would you like to have the names be [1/2]"
		echo " 1 - Numbered (name00, name01..)"
		echo " 2 - Manually defined"
		read -n1 C
		echo ""
		while [[ $C != '1' ]] && [[ $C != '2' ]]; do
			echo "Invalid selection [1/2]"
			read -n1 C
			echo ""
		done
	fi
	if [ -z $C ]; then
		echo "What name would you like for your new host?"
		read N
		NAMES=($N)
		unset COUNT
	elif [[ $C == '1' ]]; then
		echo "What base name would you like to use before the number?"
		read N
		NAMES=($N)
	else
		let COUNT=($COUNT - 1)
		for i in $(seq 0 $COUNT); do
			echo "What name would you like to use for Host $i?"
			read N
			NAMES+=($N)
		done
		unset COUNT
	fi

	if [ $REGENERATE == 'y' ] || [ ! $REGENERATE == 'Y' ]; then
		echo "Starting Debian Preseed configuration. Items marked with * are not validated. See '-h' more info."

		# LOCALE
		FALLBACK="en_US"
		if [ ! -z $LOCALE ]; then
			FALLBACK=$LOCALE
		fi
		echo "* What locale would you like to use ($FALLBACK)?"
		read CHOICE
		if [[ $CHOICE != '' ]]; then
			LOCALE=$CHOICE
		else
			LOCALE=$FALLBACK
		fi

		# KEYBOARD
		FALLBACK="en"
		if [ ! -z $KEYBOARD ]; then
			FALLBACK=$KEYBOARD
		fi
		echo "* What keyboard would you like to use ($FALLBACK)?"
		read CHOICE
		if [[ $CHOICE != '' ]]; then
			KEYBOARD=$CHOICE
		elif [ -z $LOCALE ]; then
			KEYBOARD=$FALLBACK
		fi

		# TIMEZONE
		FALLBACK="UTC"
		if [ ! -z $TIMEZONE ]; then
			FALLBACK=$TIMEZONE
		fi
		echo "* What timezone would you like to choose ($FALLBACK)?"
		read CHOICE
		if [[ $CHOICE != '' ]]; then
			LOCALE=$CHOICE
		elif [ -z $LOCALE ]; then
			LOCALE=$FALLBACK
		fi

		# PASSWORD
		A=1
		if [ ! -z $PASSWORD ] && [ ! -z $AUTHORIZEDKEYS ]; then
			A=3
		elif [ -z $PASSWORD ]; then
			A=2
		fi
		echo "How would you like to handle root logins [1-3] ($A)?"
		echo " 1 - Password only"
		echo " 2 - Authorized SSH Key only"
		echo " 3 - Password and Authorized SSH Key"
		read -n1 CHOICE
		echo ""
		while [[ $CHOICE != '1' ]] && [[ $CHOICE != '2' ]] && [[ $CHOICE != '3' ]]; do
			echo "Invalid selection [1-3]"
			read -n1 CHOICE
			echo ""
		done
		if [ $A == 1 ] || [ $A == 3 ]; then
			FALLBACK="MCPassw0rd!"
			if [ ! -z $PASSWORD ]; then
				FALLBACK=$PASSWORD
			fi
			echo "Please enter a password ($FALLBACK):"
			read CHOICE
			if [[ $CHOICE != '' ]]; then
				PASSWORD=$CHOICE
			elif [ -z $PASSWORD ]; then
				PASSWORD=$FALLBACK
			fi
		fi
		if [ $A == 2 ] || [ $A == 3 ]; then
			if [ ! -z $AUTHORIZEDKEYS ]; then
				echo "* Provide full HTTP(S) address to your public SSH key: ($AUTHORIZEDKEYS)"
			else
				echo "* Provide full HTTP(S) address to your public SSH key:"
			fi
			read CHOICE
			if [ $CHOICE == '' ] && [ ! -z $AUTHORIZEDKEYS ]; then
				CHOICE=$AUTHORIZEDKEYS
			fi
			while ! grep -qP '^https?://' <<<$(echo $CHOICE); do
				echo "Invalid selection. Please provide full HTTP(S) address:"
				read CHOICE
			done
			AUTHORIZEDKEYS=$CHOICE
		fi
		if [ $EFI == 'N' ]; then
			echo "Enable EFI support [y/N]:"
		else
			echo "Enable EFI support [Y/n]:"
			EFI='Y'
		fi
		read YN
		while [ $YN != '' ] && [ $YN != 'y' ] && [ $YN != 'Y' ] && [ $YN != 'n' ] && [ $YN != 'N' ]; do
			echo "Invalid selection."
			read YN
		done
	fi
fi

################################################################################
# Defaults
################################################################################

if [ ! -z $COUNT ] && [[ $COUNT != ${#NAMES[@]} ]] && [[ ${#NAMES[@]} != 0 ]] && [[ ${#NAMES[@]} != 1 ]]; then
	echo "-c provided with incompatible number of names. If you want to include a list of names, you should"
	echo "omit the '-c' option. One image will be created for each name. Otherwise provide only one name and"
	echo "a suffix will automatically be added to each."
	exit
fi
if [ ! -z $COUNT ]; then
	if [[ ${#NAMES[@]} == 0 ]]; then
		NAMES=('mailcleaner')
	fi
	let COUNT=($COUNT - 1)
	if [[ ${#NAMES[@]} == 1 ]]; then
		OLD_NAMES=$NAMES
		NAMES=()
		for i in $(seq 0 $COUNT); do
			NAMES+=($(printf "%s%02d" $OLD_NAMES $i))
		done
	fi
fi
if [[ ${#NAMES[@]} == 0 ]]; then
	NAMES=()
	for i in $(seq 0 ${#NAMES[@]}); do
		NAMES+=('mailcleaner')
	done
fi
if [ -z $LOCALE ]; then
	LOCALE='en_US'
fi
if [ -z $KEYBOARD ]; then
	KEYBOARD='en'
fi
if [ -z $TIMEZONE ]; then
	TIMEZONE='UTC'
fi
if [ -z $NONFREE ]; then
	NONFREE='true'
fi
if [ -z $PASSWORD ] && [ -z $AUTHORIZEDKEYS ]; then
	PASSWORD='MCPassw0rd'
fi

if [[ $DEBUG == 1 ]]; then
	echo "INFO: Configuration:"
	printf "INFO:   NAMES - "
	for i in ${NAMES[@]}; do
		printf "$i "
	done
	printf "\n"
	echo "INFO:   LOCALE - $LOCALE"
	echo "INFO:   KEYBOARD - $KEYBOARD"
	echo "INFO:   TIMEZONE - $TIMEZONE"
	echo "INFO:   NONFREE - $NONFREE"
	echo "INFO:   PASSWORD - $PASSWORD"
	echo "INFO:   AUTHORIZEDKEYS - $AUTHORIZEDKEYS"
	echo "INFO:   EFI - $EFI"
fi

################################################################################
# Preseed file
################################################################################

if [[ $DEBUG == 1 ]]; then
	echo "INFO: fetching included packages from .preseed-packages.txt"
fi
PACKAGES=$(cat .preseed-packages.txt | tr "\n" " ")
if [[ $DEBUG == 1 ]]; then
	echo "INFO: found - $PACKAGES"
fi

if [[ $REGENERATE == 'y' ]] || [[ $REGENERATE == 'Y' ]]; then
	if [[ $DEBUG == 1 ]]; then
		echo "INFO: Writing new .debian-preseed.txt"
	fi
	if [ -z $AUTHORIZEDKEYS ] && [[ $PASSWORD == '' ]]; then
		echo "You provided neither a password nor an authorized keys url. You'll have no way to access the"
		echo "system after reboot. Aborting."
		exit
	fi
	cp debian-preseed.txt_template .debian-preseed.txt
	LOCALE="$(echo $LOCALE | sed -r 's/\//\\\\\//g')"
	sed -i "s/__LOCALE__/$LOCALE/" .debian-preseed.txt
	KEYBOARD="$(echo $KEYBOARD | sed -r 's/\//\\\\\//g')"
	sed -i "s/__KEYBOARD__/$KEYBOARD/" .debian-preseed.txt
	TIMEZONE="$(echo $TIMEZONE | sed -r 's/\//\\\\\//g')"
	sed -i "s/__TIMEZONE__/$TIMEZONE/" .debian-preseed.txt
	if [[ $NONFREE == 'true' ]]; then
		sed -i "s/__NONFREE__/true/" .debian-preseed.txt
	else
		sed -i "s/__NONFREE__/false/" .debian-preseed.txt
	fi
	PASSWORD="$(echo $PASSWORD | sed -r 's/\//\\\\\//g')"
	if [ ! -z $AUTHORIZEDKEYS ]; then
		AUTHORIZEDKEYS="$(echo $AUTHORIZEDKEYS | sed -r 's/\//\\\\\//g')"
		if [[ $PASSWORD == '' ]]; then
			sed -i "s/__USEPASSWORD__/false/" .debian-preseed.txt
			sed -i "/__PASSWORD__/d" .debian-preseed.txt
			sed -i "s/root-login boolean true/root-login boolean false/" .debian-preseed.txt
		fi
		sed -i "s/__AUTHORIZEDKEYS__/$AUTHORIZEDKEYS/" .debian-preseed.txt
	else
		sed -i "/__AUTHORIZEDKEYS__/d" .debian-preseed.txt
		sed -i "s/__USEPASSWORD__/true/" .debian-preseed.txt
		sed -i "s/__PASSWORD__/$PASSWORD/" .debian-preseed.txt
	fi
	if [ $EFI == 'Y' ] || [ $EFI == 'y' ]; then
		sed -i "s/__EFI__//" .debian-preseed.txt
	else
		sed -i "/__EFI__/d" .debian-preseed.txt
	fi
	sed -i "s/__PACKAGES__/$PACKAGES/" .debian-preseed.txt
fi

exit

################################################################################
# Image Factory
################################################################################

# Create a raw Debian netinstall disk

################################################################################
# Notes
################################################################################

# Other things that might be useful:
#
# Netinstall ISO. This should be what image-factory uses:
# https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-cd/debian-testing-amd64-netinst.iso
#
# Preconfigured Cloud image:
# https://cloud.debian.org/images/cloud/bookworm/daily/latest/debian-12-generic-amd64-daily.qcow2
