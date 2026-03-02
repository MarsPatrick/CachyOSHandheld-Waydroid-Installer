#!/bin/bash

PASSWORD=$(zenity --password --title "sudo Password Authentication")
echo -e "$PASSWORD\n" | sudo -S ls &> /dev/null
if [ $? -ne 0 ]
then
	echo "sudo password is wrong!" | \
		zenity --text-info --title "Waydroid Toolbox" --width 400 --height 200
	exit 1
fi

while true
do
Choice=$(zenity --width 850 --height 400 --list --radiolist --multiple \
	--title "Waydroid Toolbox for CachyOS Waydroid script - https://github.com/ryanrudolfoba/steamos-waydroid-installer" \
	--column "Select One" \
	--column "Option" \
	--column "Description - Read this carefully!" \
	FALSE ADBLOCK "Disable or update the custom adblock hosts file." \
	FALSE AUDIO "Enable or disable the custom audio fixes." \
	FALSE SERVICE "Start or Stop the Waydroid container service." \
	FALSE GPU "Change the GPU config - GBM or MINIGBM." \
	FALSE LAUNCHER "Add Android Waydroid Cage launcher to Game Mode." \
	FALSE NETWORK "Reinitialize firewall configuration - use this when WIFI is not working." \
	FALSE UNINSTALL "Choose this to uninstall Waydroid and revert any changes made." \
	TRUE EXIT "***** Exit the Waydroid Toolbox *****")

if [ $? -eq 1 ] || [ "$Choice" == "EXIT" ]
then
	echo "User pressed CANCEL / EXIT."
	exit

elif [ "$Choice" == "NETWORK" ]
then
	# Reset and reconfigure ufw rules for waydroid0
	echo -e "$PASSWORD\n" | sudo -S ufw delete allow in on waydroid0 &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S ufw delete allow out on waydroid0 &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S ufw delete route allow in on waydroid0 &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S ufw delete route allow out on waydroid0 &> /dev/null

	echo -e "$PASSWORD\n" | sudo -S ufw allow in on waydroid0 &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S ufw allow out on waydroid0 &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S ufw route allow in on waydroid0 &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S ufw route allow out on waydroid0 &> /dev/null

	zenity --warning --title "Waydroid Toolbox" \
		--text "Waydroid network configuration completed!" --width 350 --height 75

elif [ "$Choice" == "ADBLOCK" ]
then
	ADBLOCK_Choice=$(zenity --width 600 --height 250 --list --radiolist --multiple \
		--title "Waydroid Toolbox" \
		--column "Select One" \
		--column "Option" \
		--column "Description - Read this carefully!" \
		FALSE DISABLE "Disable the custom adblock hosts file." \
		FALSE ENABLE "Enable the custom adblock hosts file." \
		FALSE UPDATE "Update and enable the custom adblock hosts file." \
		TRUE MENU "***** Go back to Waydroid Toolbox Main Menu *****")

	if [ $? -eq 1 ] || [ "$ADBLOCK_Choice" == "MENU" ]
	then
		echo "User pressed CANCEL. Going back to main menu."

	elif [ "$ADBLOCK_Choice" == "DISABLE" ]
	then
		echo -e "$PASSWORD\n" | sudo -S mv \
			/var/lib/waydroid/overlay/system/etc/hosts \
			/var/lib/waydroid/overlay/system/etc/hosts.disable &> /dev/null

		zenity --warning --title "Waydroid Toolbox" \
			--text "Custom adblock hosts file has been disabled!" --width 350 --height 75

	elif [ "$ADBLOCK_Choice" == "ENABLE" ]
	then
		echo -e "$PASSWORD\n" | sudo -S mv \
			/var/lib/waydroid/overlay/system/etc/hosts.disable \
			/var/lib/waydroid/overlay/system/etc/hosts &> /dev/null

		zenity --warning --title "Waydroid Toolbox" \
			--text "Custom adblock hosts file has been enabled!" --width 350 --height 75

	elif [ "$ADBLOCK_Choice" == "UPDATE" ]
	then
		echo -e "$PASSWORD\n" | sudo -S rm -f \
			/var/lib/waydroid/overlay/system/etc/hosts.disable &> /dev/null
		echo -e "$PASSWORD\n" | sudo -S wget \
			https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts \
			-O /var/lib/waydroid/overlay/system/etc/hosts

		zenity --warning --title "Waydroid Toolbox" \
			--text "Custom adblock hosts file has been updated!" --width 350 --height 75
	fi

elif [ "$Choice" == "GPU" ]
then
	GPU_Choice=$(zenity --width 600 --height 220 --list --radiolist --multiple \
		--title "Waydroid Toolbox" \
		--column "Select One" \
		--column "Option" \
		--column "Description - Read this carefully!" \
		FALSE GBM "Use gbm config for GPU." \
		FALSE MINIGBM "Use minigbm_gbm_mesa for GPU (default)." \
		TRUE MENU "***** Go back to Waydroid Toolbox Main Menu *****")

	if [ $? -eq 1 ] || [ "$GPU_Choice" == "MENU" ]
	then
		echo "User pressed CANCEL. Going back to main menu."

	elif [ "$GPU_Choice" == "GBM" ]
	then
		echo -e "$PASSWORD\n" | sudo -S sed -i \
			"s/ro.hardware.gralloc=.*/ro.hardware.gralloc=gbm/g" \
			/var/lib/waydroid/waydroid_base.prop

		zenity --warning --title "Waydroid Toolbox" \
			--text "gbm is now in use!" --width 350 --height 75

	elif [ "$GPU_Choice" == "MINIGBM" ]
	then
		echo -e "$PASSWORD\n" | sudo -S sed -i \
			"s/ro.hardware.gralloc=.*/ro.hardware.gralloc=minigbm_gbm_mesa/g" \
			/var/lib/waydroid/waydroid_base.prop

		zenity --warning --title "Waydroid Toolbox" \
			--text "minigbm_gbm_mesa is now in use!" --width 350 --height 75
	fi

elif [ "$Choice" == "AUDIO" ]
then
	AUDIO_Choice=$(zenity --width 600 --height 220 --list --radiolist --multiple \
		--title "Waydroid Toolbox" \
		--column "Select One" \
		--column "Option" \
		--column "Description - Read this carefully!" \
		FALSE DISABLE "Disable the custom audio config." \
		FALSE ENABLE "Enable the custom audio config to lower audio latency." \
		TRUE MENU "***** Go back to Waydroid Toolbox Main Menu *****")

	if [ $? -eq 1 ] || [ "$AUDIO_Choice" == "MENU" ]
	then
		echo "User pressed CANCEL. Going back to main menu."

	elif [ "$AUDIO_Choice" == "DISABLE" ]
	then
		echo -e "$PASSWORD\n" | sudo -S mv \
			/var/lib/waydroid/overlay/system/etc/init/audio.rc \
			/var/lib/waydroid/overlay/system/etc/init/audio.rc.disable &> /dev/null

		zenity --warning --title "Waydroid Toolbox" \
			--text "Custom audio config has been disabled!" --width 350 --height 75

	elif [ "$AUDIO_Choice" == "ENABLE" ]
	then
		echo -e "$PASSWORD\n" | sudo -S mv \
			/var/lib/waydroid/overlay/system/etc/init/audio.rc.disable \
			/var/lib/waydroid/overlay/system/etc/init/audio.rc &> /dev/null

		zenity --warning --title "Waydroid Toolbox" \
			--text "Custom audio config has been enabled!" --width 350 --height 75
	fi

elif [ "$Choice" == "SERVICE" ]
then
	SERVICE_Choice=$(zenity --width 600 --height 220 --list --radiolist --multiple \
		--title "Waydroid Toolbox" \
		--column "Select One" \
		--column "Option" \
		--column "Description - Read this carefully!" \
		FALSE START "Start the Waydroid container service." \
		FALSE STOP "Stop the Waydroid container service." \
		TRUE MENU "***** Go back to Waydroid Toolbox Main Menu *****")

	if [ $? -eq 1 ] || [ "$SERVICE_Choice" == "MENU" ]
	then
		echo "User pressed CANCEL. Going back to main menu."

	elif [ "$SERVICE_Choice" == "START" ]
	then
		echo -e "$PASSWORD\n" | sudo -S waydroid-container-start
		waydroid session start &
		sleep 5

		zenity --warning --title "Waydroid Toolbox" \
			--text "Waydroid container service has been started!" --width 350 --height 75

	elif [ "$SERVICE_Choice" == "STOP" ]
	then
		waydroid session stop
		echo -e "$PASSWORD\n" | sudo -S waydroid-container-stop
		pkill kwallet

		zenity --warning --title "Waydroid Toolbox" \
			--text "Waydroid container service has been stopped!" --width 350 --height 75
	fi

elif [ "$Choice" == "LAUNCHER" ]
then
	steamos-add-to-steam "$HOME/Android_Waydroid/Android_Waydroid_Cage.sh"
	sleep 5
	zenity --warning --title "Waydroid Toolbox" \
		--text "Android Waydroid Cage launcher has been added to Game Mode!" --width 450 --height 75

elif [ "$Choice" == "UNINSTALL" ]
then
	UNINSTALL_Choice=$(zenity --width 600 --height 220 --list --radiolist --multiple \
		--title "Waydroid Toolbox" \
		--column "Select One" \
		--column "Option" \
		--column "Description - Read this carefully!" \
		FALSE WAYDROID "Uninstall Waydroid but keep the Android user data." \
		FALSE FULL "Uninstall Waydroid and delete the Android user data." \
		TRUE MENU "***** Go back to Waydroid Toolbox Main Menu *****")

	if [ $? -eq 1 ] || [ "$UNINSTALL_Choice" == "MENU" ]
	then
		echo "User pressed CANCEL. Going back to main menu."

	elif [ "$UNINSTALL_Choice" == "WAYDROID" ]
	then
		# Stop waydroid container
		echo -e "$PASSWORD\n" | sudo -S systemctl stop waydroid-container

		# Remove kernel module and waydroid packages
		echo -e "$PASSWORD\n" | sudo -S pacman -R --noconfirm \
			binder_linux-dkms fakeroot debugedit dkms \
			libglibutil libgbinder python-gbinder waydroid \
			wlroots cage wlr-randr &> /dev/null

		# Delete waydroid directories and config
		echo -e "$PASSWORD\n" | sudo -S rm -rf \
			~/waydroid /var/lib/waydroid /usr/lib/waydroid \
			/etc/waydroid-extra ~/AUR &> /dev/null

		# Delete waydroid scripts and sudoers
		echo -e "$PASSWORD\n" | sudo -S rm -f \
			/etc/sudoers.d/zzzzzzzz-waydroid \
			/etc/modules-load.d/waydroid_binder.conf \
			/etc/modprobe.d/waydroid_binder.conf \
			/usr/bin/waydroid-startup-scripts \
			/usr/bin/waydroid-shutdown-scripts &> /dev/null

		# Delete desktop shortcut and Android_Waydroid folder
		rm -f "$HOME/Desktop/Waydroid-Toolbox" &> /dev/null
		rm -rf "$HOME/Android_Waydroid/" &> /dev/null

		zenity --warning --title "Waydroid Toolbox" \
			--text "Waydroid has been uninstalled! Goodbye!" --width 600 --height 75
		exit

	elif [ "$UNINSTALL_Choice" == "FULL" ]
	then
		# Stop waydroid container
		echo -e "$PASSWORD\n" | sudo -S systemctl stop waydroid-container

		# Remove kernel module and waydroid packages
		echo -e "$PASSWORD\n" | sudo -S pacman -R --noconfirm \
			binder_linux-dkms fakeroot debugedit dkms \
			libglibutil libgbinder python-gbinder waydroid \
			wlroots cage wlr-randr &> /dev/null

		# Delete waydroid directories, config and user data
		echo -e "$PASSWORD\n" | sudo -S rm -rf \
			~/waydroid /var/lib/waydroid /usr/lib/waydroid \
			/etc/waydroid-extra \
			~/.local/share/waydroid \
			~/.local/share/applications/waydroid* \
			~/AUR &> /dev/null

		# Delete waydroid scripts and sudoers
		echo -e "$PASSWORD\n" | sudo -S rm -f \
			/etc/sudoers.d/zzzzzzzz-waydroid \
			/etc/modules-load.d/waydroid_binder.conf \
			/etc/modprobe.d/waydroid_binder.conf \
			/usr/bin/waydroid-startup-scripts \
			/usr/bin/waydroid-shutdown-scripts &> /dev/null

		# Delete desktop shortcuts and Android_Waydroid folder
		rm -f "$HOME/Desktop/Waydroid-Toolbox" &> /dev/null
		rm -f "$HOME/Desktop/Waydroid-Updater" &> /dev/null
		rm -rf "$HOME/Android_Waydroid/" &> /dev/null

		zenity --warning --title "Waydroid Toolbox" \
			--text "Waydroid and Android user data has been uninstalled! Goodbye!" --width 600 --height 75
		exit
	fi
fi
done