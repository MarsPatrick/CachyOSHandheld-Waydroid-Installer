#!/bin/bash
echo "This will clone the latest version of the CachyOS Waydroid Installer script and perform an update."
sleep 5
cd ~/
rm -rf ~/CachyOSHandheld-Waydroid-Installer
git clone --depth=1 https://github.com/MarsPatrick/CachyOSHandheld-Waydroid-Installer.git
cd ~/CachyOSHandheld-Waydroid-Installer
chmod +x cachyos-waydroid-installer.sh
./cachyos-waydroid-installer.sh