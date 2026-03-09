#!/bin/bash

# ─── Functions ────────────────────────────────────────────────────────────────

mount_waydroid_var () {
	# Initialize and configure custom /var/lib/waydroid
	# First make sure /var/lib/waydroid is not already mounted
	echo -e "$current_password\n" | sudo -S umount /var/lib/waydroid &> /dev/null
	echo -e "$current_password\n" | sudo -S losetup -d $(losetup | grep waydroid.img | cut -d " " -f1) &> /dev/null

	# Step 1 - Decompress waydroid.img.gz using absolute path
	echo "Decompressing waydroid.img.gz..."
	gunzip -k -f "$WORKING_DIR/extras/waydroid.img.gz"
	if [ $? -ne 0 ]; then
		echo "Error decompressing waydroid.img.gz!"
		return 1
	fi
	echo "Decompressed OK. Size: $(ls -lh $WORKING_DIR/extras/waydroid.img | awk '{print $5}')"

	# Step 2 - Format as ext4
	echo "Formatting waydroid.img as ext4..."
	echo -e "$current_password\n" | sudo -S mkfs.ext4 -F "$WORKING_DIR/extras/waydroid.img"
	if [ $? -ne 0 ]; then
		echo "Error formatting waydroid.img!"
		return 1
	fi
	echo "Format OK."

	# Step 3 - Attach loop device and get its name in one command
	echo "Attaching loop device..."
	ROOTDEV=$(echo -e "$current_password\n" | sudo -S losetup --find --show "$WORKING_DIR/extras/waydroid.img" 2>/dev/null)
	if [ -z "$ROOTDEV" ]; then
		# fallback: try mounting directly with -o loop
		echo "losetup --find --show failed, trying direct mount..."
		echo -e "$current_password\n" | sudo -S mount -o loop "$WORKING_DIR/extras/waydroid.img" /var/lib/waydroid
		if [ $? -ne 0 ]; then
			echo "Error mounting waydroid.img!"
			return 1
		fi
		echo "Mounted OK via direct loop mount."
		return 0
	fi
	echo "Loop device: $ROOTDEV"

	# Step 4 - Mount
	echo "Mounting $ROOTDEV to /var/lib/waydroid..."
	echo -e "$current_password\n" | sudo -S mount "$ROOTDEV" /var/lib/waydroid
	if [ $? -ne 0 ]; then
		echo "Error mounting $ROOTDEV to /var/lib/waydroid!"
		return 1
	fi
	echo "Mounted OK."
}

unmount_waydroid_var () {
	# Unmount the custom /var/lib/waydroid
	echo -e "$current_password\n" | sudo -S umount /var/lib/waydroid &> /dev/null
	echo -e "$current_password\n" | sudo -S losetup -d $(losetup | grep waydroid.img | cut -d " " -f1) &> /dev/null
}

cleanup_exit () {
	echo "Something went wrong! Performing cleanup. Run the script again to install Waydroid."

	# Remove installed packages
	echo -e "$current_password\n" | sudo -S pacman -R --noconfirm \
		libglibutil libgbinder python-gbinder waydroid \
		wlroots cage wlr-randr &> /dev/null

	# Unmount binderfs and remove symlinks
	echo -e "$current_password\n" | sudo -S rm -f /dev/binder /dev/hwbinder /dev/vndbinder &> /dev/null
	echo -e "$current_password\n" | sudo -S umount /dev/binderfs &> /dev/null
	echo -e "$current_password\n" | sudo -S rm -rf /dev/binderfs &> /dev/null

	# Disable and remove waydroid-binder service
	echo -e "$current_password\n" | sudo -S systemctl disable waydroid-binder.service &> /dev/null
	echo -e "$current_password\n" | sudo -S rm -f /etc/systemd/system/waydroid-binder.service &> /dev/null
	echo -e "$current_password\n" | sudo -S systemctl daemon-reload &> /dev/null

	# Unmount and delete waydroid directories
	echo -e "$current_password\n" | sudo -S umount /var/lib/waydroid &> /dev/null
	echo -e "$current_password\n" | sudo -S losetup -d $(losetup | grep waydroid.img | cut -d " " -f1) &> /dev/null
	echo -e "$current_password\n" | sudo -S rm -rf /var/lib/waydroid &> /dev/null
	echo -e "$current_password\n" | sudo -S rm -f \
		/etc/sudoers.d/zzzzzzzz-waydroid \
		/etc/modules-load.d/waydroid_binder.conf \
		/etc/modprobe.d/waydroid_binder.conf &> /dev/null
	echo -e "$current_password\n" | sudo -S rm -f /usr/bin/waydroid* &> /dev/null

	# Delete desktop shortcuts and Android_Waydroid folder
	rm -f "$CURRENT_HOME/Desktop/Waydroid-Updater" &> /dev/null
	rm -f "$CURRENT_HOME/Desktop/Waydroid-Toolbox" &> /dev/null
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

uninstall_waydroid () {
	echo "Uninstalling existing Waydroid installation..."
	echo -e "$current_password\n" | sudo -S systemctl stop waydroid-container.service &>/dev/null
	echo -e "$current_password\n" | sudo -S waydroid session stop &>/dev/null
	echo -e "$current_password\n" | sudo -S pacman -Rns --noconfirm waydroid python-gbinder libgbinder libglibutil &>/dev/null

	unmount_waydroid_var

	# Remove binderfs symlinks and unmount
	echo -e "$current_password\n" | sudo -S rm -f /dev/binder /dev/hwbinder /dev/vndbinder &>/dev/null
	echo -e "$current_password\n" | sudo -S umount /dev/binderfs &>/dev/null
	echo -e "$current_password\n" | sudo -S rm -rf /dev/binderfs &>/dev/null

	# Disable and remove waydroid-binder service
	echo -e "$current_password\n" | sudo -S systemctl disable waydroid-binder.service &>/dev/null
	echo -e "$current_password\n" | sudo -S rm -f /etc/systemd/system/waydroid-binder.service &>/dev/null
	echo -e "$current_password\n" | sudo -S systemctl daemon-reload &>/dev/null

	# Delete waydroid directories and configs
	echo -e "$current_password\n" | sudo -S rm -rf /var/lib/waydroid /etc/waydroid-extra &>/dev/null
	echo -e "$current_password\n" | sudo -S rm -f \
		/etc/sudoers.d/zzzzzzzz-waydroid \
		/usr/bin/waydroid-startup-scripts \
		/usr/bin/waydroid-shutdown-scripts \
		/usr/bin/waydroid-mount \
		/usr/bin/waydroid-firewall &>/dev/null

	rm -rf "$CURRENT_HOME/Android_Waydroid" &>/dev/null
	rm -f "$CURRENT_HOME/Desktop/Waydroid-Toolbox" "$CURRENT_HOME/Desktop/Waydroid-Updater" &>/dev/null
	echo "Waydroid has been uninstalled."
}