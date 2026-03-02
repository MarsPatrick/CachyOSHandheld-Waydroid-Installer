#!/bin/bash

export RESOLUTION=$(xdpyinfo | awk '/dimensions/{print $2}')
export WAYDROID_DIR="$HOME/Android_Waydroid"

# Detect wlr-randr output name dynamically (not hardcoded to X11-1)
export WLR_OUTPUT=$(wlr-randr | head -1 | cut -d " " -f1)

# Mount /var/lib/waydroid
sudo /usr/bin/waydroid-mount

# Check if waydroid binary exists
if [ ! -f /usr/bin/waydroid ]
then
	kdialog --sorry "Cannot start Waydroid. Waydroid does not exist! \
	\nIf you recently performed a system update, you may need to re-install or update Waydroid. \
	\n\nFollow the Waydroid upgrade guide here - https://youtu.be/CJAMwIb_oI0 \
	\n\nCachyOS version: $(cat /etc/os-release | grep -i VERSION_ID | cut -d '=' -f2) \
	\nKernel version: $(uname -r)"
	exit 1
fi

# Fix intermittent broken internet connection and start waydroid container service
sudo /usr/bin/waydroid-firewall

# Check the status of waydroid container
systemctl status waydroid-container.service | grep -i running
if [ $? -ne 0 ]
then
	kdialog --sorry "Something went wrong. Waydroid container did not initialize correctly."
	exit 1
fi

# Check if a non-Steam shortcut has an app as the launch option
if [ -z "$1" ]
then
	# No launch option provided - launch Waydroid via cage and show full UI
	cage -- bash -c 'wlr-randr --output '"$WLR_OUTPUT"' --custom-mode $RESOLUTION ; \
		/usr/bin/waydroid show-full-ui $@ & \

		sleep 10 ; \
		waydroid prop set persist.waydroid.fake_wifi $(cat '"$WAYDROID_DIR"'/fake_wifi) ; \
		waydroid prop set persist.waydroid.fake_touch $(cat '"$WAYDROID_DIR"'/fake_touch) ; \

		sudo /usr/bin/waydroid-startup-scripts'
else
	# Launch option provided - start session, launch the app, then show full UI
	cage -- env PACKAGE="$1" bash -c 'wlr-randr --output '"$WLR_OUTPUT"' --custom-mode $RESOLUTION ; \
		/usr/bin/waydroid session start $@ & \

		sleep 10 ; \
		waydroid prop set persist.waydroid.fake_wifi $(cat '"$WAYDROID_DIR"'/fake_wifi) ; \
		waydroid prop set persist.waydroid.fake_touch $(cat '"$WAYDROID_DIR"'/fake_touch) ; \

		sudo /usr/bin/waydroid-startup-scripts ; \

		sleep 1 ; \
		/usr/bin/waydroid app launch $PACKAGE & \

		sleep 1 ; \
		/usr/bin/waydroid show-full-ui $@ &'
fi

# Run shutdown scripts to cleanup when waydroid exits
while [ -n "$(pgrep cage)" ]
do
	sleep 1
done

sudo /usr/bin/waydroid-shutdown-scripts