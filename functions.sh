#!/bin/bash

# ─── Functions ────────────────────────────────────────────────────────────────

mount_waydroid_var () {
	# Initialize and configure custom /var/lib/waydroid
	# First make sure /var/lib/waydroid is not already mounted
	echo -e "$current_password\n" | sudo -S umount /var/lib/waydroid &> /dev/null
	echo -e "$current_password\n" | sudo -S losetup -d $(losetup | grep waydroid.img | cut -d " " -f1) &> /dev/null

	# Prepare the custom /var/lib/waydroid from the compressed image in extras/
	gunzip -k -f extras/waydroid.img.gz && \
		mkfs.ext4 -F extras/waydroid.img && \
		ROOTDEV=$(sudo losetup --find --show extras/waydroid.img) && \
		echo -e "$current_password\n" | sudo -S mount $ROOTDEV /var/lib/waydroid
}

unmount_waydroid_var () {
	# Unmount the custom /var/lib/waydroid
	echo -e "$current_password\n" | sudo -S umount /var/lib/waydroid &> /dev/null
	echo -e "$current_password\n" | sudo -S losetup -d $(losetup | grep waydroid.img | cut -d " " -f1) &> /dev/null
}

cleanup_exit () {
	# Call this function to perform cleanup when something goes wrong

	echo "Something went wrong! Performing cleanup. Run the script again to install Waydroid."

	# Remove installed packages
	# Note: linux-cachyos-deckify-headers kept intentionally (was pre-existing or needed for other things)
	echo -e "$current_password\n" | sudo -S pacman -R --noconfirm \
		libglibutil libgbinder python-gbinder waydroid \
		wlroots cage wlr-randr binder_linux-dkms \
		fakeroot debugedit dkms &> /dev/null

	# Unmount the custom /var/lib/waydroid
	echo -e "$current_password\n" | sudo -S umount /var/lib/waydroid &> /dev/null
	echo -e "$current_password\n" | sudo -S losetup -d $(losetup | grep waydroid.img | cut -d " " -f1) &> /dev/null

	# Delete waydroid directories and configs
	echo -e "$current_password\n" | sudo -S rm -rf /var/lib/waydroid &> /dev/null
	echo -e "$current_password\n" | sudo -S rm -f \
		/etc/sudoers.d/zzzzzzzz-waydroid \
		/etc/modules-load.d/waydroid_binder.conf \
		/etc/modprobe.d/waydroid_binder.conf &> /dev/null
	echo -e "$current_password\n" | sudo -S rm -f /usr/bin/waydroid* &> /dev/null

	# Delete desktop shortcuts
	rm -f "$CURRENT_HOME/Desktop/Waydroid-Updater" &> /dev/null
	rm -f "$CURRENT_HOME/Desktop/Waydroid-Toolbox" &> /dev/null

	# Delete Android_Waydroid folder
	rm -rf "$CURRENT_HOME/Android_Waydroid" &> /dev/null

	# Re-enable Decky Loader if present
	if [ -f "$CURRENT_HOME/homebrew/services/PluginLoader" ]; then
		echo "Re-enabling the Decky Loader plugin loader service."
		echo -e "$current_password\n" | sudo -S systemctl start plugin_loader.service
	fi

	echo "Cleanup completed. Please open an issue on the GitHub repo."
	exit 1
}

prepare_custom_image_location () {
	# Call this when deploying a custom Android image
	# Custom images need to be placed in /etc/waydroid-extra/images
	echo -e "$current_password\n" | sudo -S mkdir -p /etc/waydroid-extra &> /dev/null
	echo -e "$current_password\n" | sudo -S mkdir -p /var/lib/waydroid/custom &> /dev/null
	echo -e "$current_password\n" | sudo -S ln -sf /var/lib/waydroid/custom \
		/etc/waydroid-extra/images &> /dev/null
}

download_image () {
	local src=$1
	local src_hash=$2
	local dest=$3
	local dest_zip="$dest.zip"
	local name=$4
	local hash

	echo "Downloading $name image..."
	echo -e "$current_password\n" | sudo -S curl -o "$dest_zip" "$src" -L

	echo "Verifying hash..."
	hash=$(sha256sum "$dest_zip" | awk '{print $1}')
	if [[ "$hash" != "$src_hash" ]]; then
		echo "SHA256 hash mismatch for $name image - download may be corrupted. Try running the script again."
		cleanup_exit
	fi
	echo "Hash verified OK."

	echo "Extracting archive..."
	echo -e "$current_password\n" | sudo -S unzip -o "$dest_zip" -d "$dest"
	echo -e "$current_password\n" | sudo -S rm -f "$dest_zip"
}

apply_android_custom_config () {
	# Apply custom config for controller detection, root and fingerprint spoof

	# Append base props (controller config, disable root)
	echo "" | sudo tee -a /var/lib/waydroid/waydroid_base.prop > /dev/null
	cat extras/waydroid_base.prop | sudo tee -a /var/lib/waydroid/waydroid_base.prop > /dev/null

	# Apply fingerprint spoof depending on Android variant chosen
	if [ "$Android_Choice" == "A13_NO_GAPPS" ] || \
	   [ "$Android_Choice" == "A13_GAPPS" ] || \
	   [ "$Android_Choice" == "A13_CUSTOM" ]; then
		echo "" | sudo tee -a /var/lib/waydroid/waydroid_base.prop > /dev/null
		cat extras/android_spoof.prop | sudo tee -a /var/lib/waydroid/waydroid_base.prop > /dev/null

	elif [ "$Android_Choice" == "TV13_NO_GAPPS" ] || \
	     [ "$Android_Choice" == "TV13_GAPPS" ]; then
		echo "Applying TV13 fingerprint spoof."
		echo "" | sudo tee -a /var/lib/waydroid/waydroid_base.prop > /dev/null
		cat extras/androidtv_spoof.prop | sudo tee -a /var/lib/waydroid/waydroid_base.prop > /dev/null
	fi

	# Change GPU rendering to minigbm_gbm_mesa
	echo -e "$current_password\n" | sudo -S sed -i \
		"s/ro.hardware.gralloc=.*/ro.hardware.gralloc=minigbm_gbm_mesa/g" \
		/var/lib/waydroid/waydroid_base.prop
}

install_android_extras () {
	# Install ARM translation layer (libhoudini/libndk) and widevine
	# Uses casualsnek/aleasto waydroid_script via Python venv

	python3 -m venv "$WAYDROID_SCRIPT_DIR/venv"
	"$WAYDROID_SCRIPT_DIR/venv/bin/pip" install -r "$WAYDROID_SCRIPT_DIR/requirements.txt" &> /dev/null

	echo "$ARM_Choice installation started:"
	echo -e "$current_password\n" | sudo -S \
		"$WAYDROID_SCRIPT_DIR/venv/bin/python3" "$WAYDROID_SCRIPT_DIR/main.py" \
		-a13 install {$ARM_Choice,widevine}

	echo "casualsnek/aleasto waydroid_script done. $ARM_Choice installed."
	echo -e "$current_password\n" | sudo -S rm -rf "$WAYDROID_SCRIPT_DIR"
}

install_android_extras_custom () {
	# Install ARM translation layer, widevine AND GAPPS
	# Use this for custom Android images (A13_CUSTOM)

	python3 -m venv "$WAYDROID_SCRIPT_DIR/venv"
	"$WAYDROID_SCRIPT_DIR/venv/bin/pip" install -r "$WAYDROID_SCRIPT_DIR/requirements.txt" &> /dev/null

	echo "$ARM_Choice installation started:"
	echo -e "$current_password\n" | sudo -S \
		"$WAYDROID_SCRIPT_DIR/venv/bin/python3" "$WAYDROID_SCRIPT_DIR/main.py" \
		-a13 install {$ARM_Choice,widevine,gapps}

	echo "casualsnek/aleasto waydroid_script done. $ARM_Choice + GAPPS installed."
	echo -e "$current_password\n" | sudo -S rm -rf "$WAYDROID_SCRIPT_DIR"
}

check_waydroid_init () {
	# Check if waydroid initialization completed without errors
	if [ $? -eq 0 ]; then
		echo "Waydroid initialization completed without errors!"
	else
		echo "Waydroid did not initialize correctly."
		echo "This could be a hash mismatch or corrupted download."
		echo "Python diagnostics:"
		echo "  whereis python: $(whereis python)"
		echo "  which python:   $(which python)"
		echo "  python version: $(python -V 2>&1)"
		cleanup_exit
	fi
}