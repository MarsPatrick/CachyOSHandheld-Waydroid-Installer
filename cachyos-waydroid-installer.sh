#!/bin/bash

clear

echo "========================================"
echo " CachyOS Waydroid Installer"
echo " Adapted from ryanrudolfoba's SteamOS script"
echo " for CachyOS Handheld / ROG Ally"
echo "========================================"
sleep 2

# ─── Variables ────────────────────────────────────────────────────────────────

WORKING_DIR=$(pwd)
LOGFILE=$WORKING_DIR/logfile
CURRENT_USER=$(whoami)
CURRENT_HOME=$(eval echo "~$CURRENT_USER")

WAYDROID_SCRIPT=https://github.com/casualsnek/waydroid_script.git
WAYDROID_SCRIPT_DIR=$(mktemp -d)/waydroid_script

ARM_Choice=libhoudini

# Android 13 TV builds
ANDROID13_TV_OTA=https://ota.supechicken666.dev

# Android 13 Custom build
ANDROID13_IMG=https://github.com/ryanrudolfoba/SteamOS-Waydroid-Installer/releases/download/Android13-PvZ2/lineage-20-20251210-UNOFFICIAL-10MinuteSteamDeckGamer-Waydroid.zip
ANDROID13_IMG_HASH=aafdd4ef69e8a11d64ba02e881c1697d6a3ee4fa4c1fb97e33abc6da5f4bb6d4

# ─── Load functions ───────────────────────────────────────────────────────────

source functions.sh

# ─── Password prompt (GUI) ────────────────────────────────────────────────────

while true; do
    current_password=$(zenity --password --title "CachyOS Waydroid Installer" 2>/dev/null)
    if [ $? -ne 0 ]; then
        zenity --error --text="Cancelled. Exiting." 2>/dev/null
        exit 1
    fi
    if [ -z "$current_password" ]; then
        zenity --error --text="Password cannot be empty. Please try again." 2>/dev/null
        continue
    fi
    echo -e "$current_password\n" | sudo -S -k ls &> /dev/null
    if [ $? -eq 0 ]; then
        break
    else
        zenity --error --text="Sudo password is wrong! Please try again." 2>/dev/null
    fi
done

# ─── Sanity checks ────────────────────────────────────────────────────────────

source sanity-checks.sh

# ─── Detect existing installation ────────────────────────────────────────────

if pacman -Qi waydroid &>/dev/null || [ -d "$CURRENT_HOME/Android_Waydroid" ]; then
    zenity --question \
        --title="Waydroid Already Installed" \
        --text="Waydroid is already installed. Do you want to uninstall it and reinstall from scratch?" \
        2>/dev/null
    if [ $? -eq 0 ]; then
        uninstall_waydroid
    else
        echo "Exiting without changes."
        exit 0
    fi
fi

# ─── Waydroid source choice ───────────────────────────────────────────────────

WAYDROID_SOURCE=$(zenity --width 600 --height 200 --list --radiolist \
    --title "CachyOS Waydroid Installer - Waydroid Source" \
    --column "Select" --column "Option" --column "Description" \
    TRUE PACMAN "Install Waydroid from CachyOS official repos (recommended)" \
    FALSE ZST "Install Waydroid from precompiled .zst packages (ryanrudolfoba's repo)" \
    2>/dev/null)

if [ $? -eq 1 ] || [ -z "$WAYDROID_SOURCE" ]; then
    echo "Cancelled. Exiting."
    exit 0
fi

# ─── Clone waydroid_script ────────────────────────────────────────────────────

echo "Cloning casualsnek/aleasto waydroid_script..."
git clone --depth=1 "$WAYDROID_SCRIPT" "$WAYDROID_SCRIPT_DIR" &>/dev/null
if [ $? -ne 0 ]; then
    echo "Error cloning waydroid_script repo!"
    cleanup_exit
fi
echo "waydroid_script cloned OK."

# ─── Binder via binderfs ──────────────────────────────────────────────────────
# CachyOS deckify kernel has binder compiled in (not as a module).
# Binder is exposed via binderfs - we mount it and create symlinks for Waydroid.

echo "Setting up binder via binderfs..."
echo "*** setup binderfs ***" >> "$LOGFILE"

echo -e "$current_password\n" | sudo -S mkdir -p /dev/binderfs
echo -e "$current_password\n" | sudo -S mount -t binder binder /dev/binderfs &>> "$LOGFILE"
if [ $? -ne 0 ]; then
    echo "Error mounting binderfs. Check $LOGFILE for details."
    cleanup_exit
fi

echo -e "$current_password\n" | sudo -S bash -c \
    'ls /dev/binderfs/hwbinder &>/dev/null || echo -n "hwbinder" > /dev/binderfs/binder-control'
echo -e "$current_password\n" | sudo -S bash -c \
    'ls /dev/binderfs/vndbinder &>/dev/null || echo -n "vndbinder" > /dev/binderfs/binder-control'

echo -e "$current_password\n" | sudo -S ln -sf /dev/binderfs/binder /dev/binder
echo -e "$current_password\n" | sudo -S ln -sf /dev/binderfs/hwbinder /dev/hwbinder
echo -e "$current_password\n" | sudo -S ln -sf /dev/binderfs/vndbinder /dev/vndbinder

echo "Binder setup via binderfs OK."

echo "Installing waydroid-binder systemd service..."
echo -e "$current_password\n" | sudo -S cp extras/waydroid-binder.service /etc/systemd/system/waydroid-binder.service
echo -e "$current_password\n" | sudo -S systemctl daemon-reload
echo -e "$current_password\n" | sudo -S systemctl enable waydroid-binder.service
echo "waydroid-binder service installed and enabled."

# ─── System upgrade ───────────────────────────────────────────────────────────

echo "Performing full system upgrade before installing packages..."
echo "*** pacman -Syu ***" >> "$LOGFILE"
echo -e "$current_password\n" | sudo -S pacman -Syu --noconfirm &>> "$LOGFILE"
if [ $? -ne 0 ]; then
    echo "Error during system upgrade. Check $LOGFILE for details."
    cleanup_exit
fi
echo "System upgrade completed OK."

# ─── Install cage and wlr-randr ───────────────────────────────────────────────

echo "Installing cage and wlr-randr..."
echo "*** pacman install cage wlr-randr ***" >> "$LOGFILE"
echo -e "$current_password\n" | sudo -S pacman -S --noconfirm cage wlr-randr &>> "$LOGFILE"
if [ $? -ne 0 ]; then
    echo "Error installing cage/wlr-randr."
    cleanup_exit
fi
echo "cage and wlr-randr installed OK."

# ─── Install Waydroid ─────────────────────────────────────────────────────────

echo "Installing Waydroid..."
echo "*** install waydroid ***" >> "$LOGFILE"

if [ "$WAYDROID_SOURCE" == "PACMAN" ]; then
    echo -e "$current_password\n" | sudo -S pacman -S --noconfirm waydroid &>> "$LOGFILE"
else
    cd "$WORKING_DIR"
    echo -e "$current_password\n" | sudo -S pacman -U --noconfirm \
        waydroid/libgbinder*.zst \
        waydroid/libglibutil*.zst \
        waydroid/python-gbinder*.zst \
        waydroid/waydroid*.zst &>> "$LOGFILE"
fi

if [ $? -ne 0 ]; then
    echo "Error installing Waydroid."
    cleanup_exit
fi

echo "Waydroid installed OK."
echo -e "$current_password\n" | sudo -S systemctl disable waydroid-container.service

# ─── Firewall config (ufw) ────────────────────────────────────────────────────

echo "Configuring firewall for Waydroid..."
echo -e "$current_password\n" | sudo -S ufw allow in on waydroid0 &>/dev/null
echo -e "$current_password\n" | sudo -S ufw allow out on waydroid0 &>/dev/null
echo -e "$current_password\n" | sudo -S ufw route allow in on waydroid0 &>/dev/null
echo -e "$current_password\n" | sudo -S ufw route allow out on waydroid0 &>/dev/null
echo "Firewall configured."

# ─── Setup directories and custom scripts ─────────────────────────────────────

mkdir -p "$CURRENT_HOME/Android_Waydroid/extras"

echo -e "$current_password\n" | sudo -S cp extras/waydroid-startup-scripts /usr/bin/waydroid-startup-scripts
echo -e "$current_password\n" | sudo -S cp extras/waydroid-shutdown-scripts /usr/bin/waydroid-shutdown-scripts
echo -e "$current_password\n" | sudo -S cp extras/waydroid-mount /usr/bin/waydroid-mount
echo -e "$current_password\n" | sudo -S cp extras/waydroid-firewall /usr/bin/waydroid-firewall
echo -e "$current_password\n" | sudo -S chmod +x \
    /usr/bin/waydroid-startup-scripts \
    /usr/bin/waydroid-shutdown-scripts \
    /usr/bin/waydroid-mount \
    /usr/bin/waydroid-firewall

echo -e "$current_password\n" | sudo -S cp extras/zzzzzzzz-waydroid /etc/sudoers.d/zzzzzzzz-waydroid
echo -e "$current_password\n" | sudo -S chown root:root /etc/sudoers.d/zzzzzzzz-waydroid

cp extras/Android_Waydroid_Cage.sh \
    extras/Waydroid-Toolbox.sh \
    extras/Waydroid-Updater.sh \
    extras/fake_wifi \
    extras/fake_touch \
    "$CURRENT_HOME/Android_Waydroid"
chmod +x "$CURRENT_HOME/Android_Waydroid"/*.sh

mkdir -p "$CURRENT_HOME/.local/share/kio/servicemenus"
cp extras/open_as_root.desktop "$CURRENT_HOME/.local/share/kio/servicemenus"
chmod +x "$CURRENT_HOME/.local/share/kio/servicemenus/open_as_root.desktop"

ln -sf "$CURRENT_HOME/Android_Waydroid/Waydroid-Toolbox.sh" "$CURRENT_HOME/Desktop/Waydroid-Toolbox"
ln -sf "$CURRENT_HOME/Android_Waydroid/Waydroid-Updater.sh" "$CURRENT_HOME/Desktop/Waydroid-Updater"

# ─── Prepare /var/lib/waydroid ────────────────────────────────────────────────

echo "Preparing /var/lib/waydroid..."
echo -e "$current_password\n" | sudo -S mkdir -p /var/lib/waydroid
mount_waydroid_var
if [ $? -ne 0 ]; then
    echo "Error mounting /var/lib/waydroid. Exiting."
    cleanup_exit
fi
echo "/var/lib/waydroid mounted OK."

# ─── Overlay files ────────────────────────────────────────────────────────────

echo -e "$current_password\n" | sudo -S mkdir -p /var/lib/waydroid/overlay/system/usr/keylayout
echo -e "$current_password\n" | sudo -S cp extras/Vendor_28de_Product_11ff.kl \
    /var/lib/waydroid/overlay/system/usr/keylayout/

echo -e "$current_password\n" | sudo -S mkdir -p /var/lib/waydroid/overlay/system/etc/init
echo -e "$current_password\n" | sudo -S cp extras/audio.rc \
    /var/lib/waydroid/overlay/system/etc/init/

echo -e "$current_password\n" | sudo -S wget -q \
    https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts \
    -O /var/lib/waydroid/overlay/system/etc/hosts

# ─── Android image choice ─────────────────────────────────────────────────────

Android_Choice=$(zenity --width 1040 --height 320 --list --radiolist \
    --title "CachyOS Waydroid Installer - Android Image" \
    --column "Select" \
    --column "Option" \
    --column "Description" \
    TRUE A13_GAPPS "Android 13 (official) with Google Play Store" \
    FALSE A13_NO_GAPPS "Android 13 (official) without Google Play Store" \
    FALSE A13_CUSTOM "Android 13 (unofficial) with new fake wifi implementation" \
    FALSE TV13_GAPPS "Android 13 TV (unofficial by SupeChicken666) with Google Play Store" \
    FALSE TV13_NO_GAPPS "Android 13 TV (unofficial by SupeChicken666) without Google Play Store" \
    FALSE EXIT "Exit this script" \
    2>/dev/null)

if [ $? -eq 1 ] || [ "$Android_Choice" == "EXIT" ] || [ -z "$Android_Choice" ]; then
    echo "Cancelled by user. Exiting."
    cleanup_exit
fi

# ─── Initialize Waydroid ──────────────────────────────────────────────────────

echo "Initializing Waydroid with choice: $Android_Choice"

case "$Android_Choice" in
    A13_GAPPS)
        echo -e "$current_password\n" | sudo -S waydroid init -s GAPPS
        check_waydroid_init
        ;;
    A13_NO_GAPPS)
        echo -e "$current_password\n" | sudo -S waydroid init
        check_waydroid_init
        ;;
    TV13_GAPPS)
        echo -e "$current_password\n" | sudo -S waydroid init \
            -c "${ANDROID13_TV_OTA}/system" \
            -v "${ANDROID13_TV_OTA}/vendor" \
            -s GAPPS
        check_waydroid_init
        ;;
    TV13_NO_GAPPS)
        echo -e "$current_password\n" | sudo -S waydroid init \
            -c "${ANDROID13_TV_OTA}/system" \
            -v "${ANDROID13_TV_OTA}/vendor"
        check_waydroid_init
        ;;
    A13_CUSTOM)
        prepare_custom_image_location
        download_image "$ANDROID13_IMG" "$ANDROID13_IMG_HASH" \
            /var/lib/waydroid/custom "Android 13 Custom Image"
        echo -e "$current_password\n" | sudo -S waydroid init
        check_waydroid_init
        ;;
esac

# ─── ARM translation, widevine, fingerprint ───────────────────────────────────

case "$Android_Choice" in
    TV13_GAPPS|TV13_NO_GAPPS)
        echo "TV13 images already include libhoudini and widevine. Skipping."
        ;;
    A13_CUSTOM)
        install_android_extras_custom
        ;;
    *)
        install_android_extras
        ;;
esac

# ─── Apply custom Android config ──────────────────────────────────────────────

cd "$WORKING_DIR"
apply_android_custom_config

# ─── Add to Steam Game Mode ───────────────────────────────────────────────────

echo "Adding Waydroid shortcut to Game Mode..."
launcher_script="$CURRENT_HOME/Android_Waydroid/Android_Waydroid_Cage.sh"
chmod +x "$launcher_script"

TMP_DESKTOP=$(mktemp --suffix=.desktop)
cat > "$TMP_DESKTOP" << EOF
[Desktop Entry]
Name=Waydroid
Exec=${launcher_script}
Path=${CURRENT_HOME}/Android_Waydroid
Type=Application
Terminal=false
Icon=application-default-icon
EOF

chmod +x "$TMP_DESKTOP"
steamos-add-to-steam "$TMP_DESKTOP"
sleep 3
rm -f "$TMP_DESKTOP"
echo "Waydroid shortcut added to Game Mode."

python3 extras/icon.py

steamos-add-to-steam /usr/bin/steamos-nested-desktop &>/dev/null
sleep 3
echo "steamos-nested-desktop shortcut added to Game Mode."

# ─── Finalize ─────────────────────────────────────────────────────────────────

echo "Unmounting /var/lib/waydroid..."
echo -e "$current_password\n" | sudo -S systemctl stop waydroid-container.service
unmount_waydroid_var
mv extras/waydroid.img "$CURRENT_HOME/Android_Waydroid/waydroid.img" 2>/dev/null

echo ""
echo "========================================"
echo " Waydroid has been successfully installed!"
echo "========================================"

if zenity --question --text="Installation complete! Do you want to return to Gaming Mode?" 2>/dev/null; then
    qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout
fi