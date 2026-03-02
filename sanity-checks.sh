#!/bin/bash

# sanity check - make sure this is running on CachyOS
DISTRO=$(cat /etc/os-release | grep -i "^ID=" | cut -d "=" -f2 | tr -d '"')
if [ "$DISTRO" == "cachyos" ]
then
	echo "CachyOS detected. Proceed to the next step."
else
	echo "This script is designed for CachyOS only."
	echo "Detected distro: $DISTRO"
	echo "Exiting."
	exit 1
fi

# sanity check - are you running this in Desktop Mode or ssh / virtual tty session?
xdpyinfo &> /dev/null
if [ $? -eq 0 ]
then
	echo "Script is running in Desktop Mode. Proceed to the next step."
else
	echo "Script is NOT running in Desktop Mode."
	echo "Please run the script in Desktop Mode as mentioned in the README. Goodbye!"
	exit 1
fi

# sanity check - make sure there is enough free space in the home partition (at least 10GB)
echo "Checking if home partition has enough free space..."
echo "Home partition has $FREE_HOME KB free."
if [ $FREE_HOME -ge 10000000 ]
then
	echo "Home partition has enough free space. Proceed to the next step."
else
	echo "Not enough space on the home partition!"
	echo "Make sure there is at least 10GB free on the home partition!"
	exit 1
fi

# sanity check - make sure sudo password is already set
if [ "$(passwd --status $(whoami) | tr -s " " | cut -d " " -f 2)" == "P" ]
then
	read -s -p "Please enter current sudo password: " current_password ; echo
	echo "Checking if the sudo password is correct..."
	echo -e "$current_password\n" | sudo -S -k ls &> /dev/null

	if [ $? -eq 0 ]
	then
		echo "Sudo password is correct. Proceed to the next step."
	else
		echo "Sudo password is wrong! Re-run the script and enter the correct sudo password."
		exit 1
	fi
else
	echo "Sudo password is blank! Set a sudo password first and then re-run the script."
	passwd
	exit 1
fi

# sanity check - is Decky Loader installed?
systemctl is-active --quiet plugin_loader.service
if [ $? -eq 0 ]
then
	echo "Decky Loader detected! Temporarily disabling the plugin loader service..."
	echo -e "$current_password\n" | sudo -S systemctl stop plugin_loader.service

	if [ $? -eq 0 ]
	then
		echo "Decky Loader plugin loader service successfully disabled."
		echo "It will be re-enabled once the script finishes, or you can reboot to re-activate it."
	else
		echo "Error stopping the Decky Loader plugin loader service. Exiting."
		exit 1
	fi
fi