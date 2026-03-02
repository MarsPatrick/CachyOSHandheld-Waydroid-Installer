# CachyOS Handheld Waydroid Installer (ROG Ally)

An adaptation of [ryanrudolfoba's SteamOS Waydroid Installer](https://github.com/ryanrudolfoba/SteamOS-Waydroid-Installer) for **CachyOS Handheld** running on the **ROG Ally**.

> Tested on CachyOS with kernel `linux-cachyos-deckify` on ROG Ally.

## What's different from the original

- No `steamos-devmode` or `steamos-readonly` — CachyOS has a writable filesystem by default
- Kernel headers use `linux-cachyos-deckify-headers` instead of `linux-neptune-*`
- Binder module is checked before building — skipped if already loaded
- Firewall uses `ufw` instead of `firewalld`
- Waydroid installed from CachyOS official repos or precompiled `.zst` packages (user choice)
- User is dynamic — not hardcoded to `deck`
- Distro sanity check — script verifies it's running on CachyOS before doing anything
- Clean uninstall on reinstall — detects existing installation and offers to wipe before reinstalling
- `wlr-randr` output detected dynamically — not hardcoded to `X11-1`

## Prerequisites

- CachyOS Handheld installed with kernel `linux-cachyos-deckify`
- `sudo` password already set
- At least 10GB free space in `/home`
- Script must be run in Desktop Mode via Konsole

## Install

```sh
cd ~/
git clone --depth=1 https://github.com/MarsPatrick/CachyOSHandheld-Waydroid-Installer.git
cd CachyOSHandheld-Waydroid-Installer
chmod +x install-waydroid-cachyos.sh
./install-waydroid-cachyos.sh
```

## Launching Waydroid

1. Go to Game Mode
2. Run the **Waydroid** launcher that was added during install

## Uninstall

1. Go to Desktop Mode
2. Launch **Waydroid-Toolbox** from the desktop shortcut
3. Select **UNINSTALL**

## Troubleshooting

- If something goes wrong, uninstall, clone the repo again and reinstall
- Make sure to run the script in Desktop Mode — not via SSH or virtual TTY
- If downloads are slow, press `CTRL-C` and run the script again

## Credits

- [ryanrudolfoba](https://github.com/ryanrudolfoba) — original SteamOS Waydroid Installer
- [waydroid devs](https://github.com/waydroid/waydroid) — the core project
- [casualsnek / aleasto](https://github.com/casualsnek/waydroid_script) — waydroid_script for ARM translation and widevine
- [SupeChicken666](https://github.com/supechicken666) — Android 13 TV images
- [@10MinuteSteamDeckGamer](https://www.youtube.com/@10MinuteSteamDeckGamer/) — original script, guides and testing

---
---

# Original README (Forked From)

> The following is the original README from [ryanrudolfoba/SteamOS-Waydroid-Installer](https://github.com/ryanrudolfoba/SteamOS-Waydroid-Installer), preserved here for reference.

---

# SteamOS Android Waydroid Installer

A collection of tools that is packaged into an easy to use script that is streamlined and tested to work with the Steam Deck running on SteamOS.
* The main program that does all the heavy lifting is [Waydroid - a container-based approach to boot a full Android system on a regular GNU/Linux system.](https://github.com/waydroid/waydroid)
* Waydroid Toolbox to easily toggle some configuration settings for Waydroid.
* [waydroid_script](https://github.com/casualsnek/waydroid_script) to easily add the libndk ARM translation layer and widevine.

**NOTE - this repository uses `main` and `testing` branches.**

**`testing`** - this is where new updates / features are pushed and sits for 1-2 weeks to make sure that bugs are squashed and eliminated. You can access it via this command -
```
git clone --depth=1 -b testing https://github.com/ryanrudolfoba/steamos-waydroid-installer
```

**`main`** this is updated after 1-2 weeks in `testing` branch. You can access it via this command -
```
git clone --depth=1 https://github.com/ryanrudolfoba/steamos-waydroid-installer
```

**Script has gone through several updates - this now allows you to install Android 11 / Android 13 and their TV counterparts - Android 11 TV / Android 13 TV!**

| [2026 SteamOS Waydroid Android Install Guide](https://www.youtube.com/watch?v=06T-h-jPVx8) | [SteamOS Waydroid Android Upgrade Guide](https://youtu.be/CJAMwIb_oI0) |
| ------------- | ------------- |
| [![image](https://github.com/user-attachments/assets/514beb00-766e-4e3e-8d2b-64b13b6a6ef0)](https://youtu.be/uZz9jdPBsb4)  | [![image](https://github.com/user-attachments/assets/88bb1e93-2f80-4ed0-82f1-1cbe78e04a2f)](https://youtu.be/CJAMwIb_oI0)  |

| [Android TV demo](https://youtu.be/gNFxrojouiM) | [Android 13 demo](https://youtu.be/5BZz8YynaUA) |
| ------------- | ------------- |
| [![image](https://github.com/user-attachments/assets/093bf362-10da-4ff6-ab3d-a3e50ea3c9f7)](https://youtu.be/gNFxrojouiM)  | [![image](https://github.com/user-attachments/assets/cdb47289-4ac6-4625-9fed-0903d624958a)](https://youtu.be/5BZz8YynaUA)  |

<details>
<summary><b>SCREENSHOTS! SCREENSHOTS! SCREENSHOTS!</b></summary>

![image](https://github.com/user-attachments/assets/a9bc05cc-87ea-43f3-a628-56b0250ae88d)

**Android 13**
![image](https://github.com/user-attachments/assets/cc9d408b-b4af-4d39-8dd3-0507e15ef8a7)
![image](https://github.com/user-attachments/assets/a3ac44b6-68bf-4a1f-bf1a-e880b320dcf0)

**Android 13 TV**
![image](https://github.com/user-attachments/assets/141c2ec6-9918-40e8-bf87-2e199fbbb3f9)
</details>

<details>
<summary><b>How to Access the Waydroid Folder in Dolphin File Manager</b></summary>

1. Launch Waydroid in Desktop Mode via konsole -
   cd ~/Android_Waydroid
   ./Android_Waydroid_Cage.sh
	
2. Wait for Waydroid to finish the boot sequence.

3. Launch Dolphin File Manager. In the address bar go to `/home/deck/.local/share/waydroid`

4. Right-click empty spot on the right pane and select `Open Dolphin File Manager as Root`

5. Enter the sudo password when prompted

6. A new Dolphin File Manager will spawn that has root access

7. From here you can now access the Waydroid folders
</details>

> [!NOTE]
> If you are going to use this script for a video tutorial, PLEASE reference on your video where you got the script! This will make the support process easier!
> And don't forget to give a shoutout to [@10MinuteSteamDeckGamer](https://www.youtube.com/@10MinuteSteamDeckGamer/) / ryanrudolf from the Philippines!

<b> If you like my work please show support by subscribing to my [YouTube channel @10MinuteSteamDeckGamer.](https://www.youtube.com/@10MinuteSteamDeckGamer/) </b> <br>
<b> I'm just passionate about Linux, Windows, how stuff works, and playing retro and modern video games on my Steam Deck! </b>

<b>Monetary donations are also encouraged if you find this project helpful. Your donation inspires me to continue research on the Steam Deck!</b>

# Disclaimer
1. Do this at your own risk!
2. This is for educational and research purposes only!

# What's New (as of Feb 20 2026)
* change from Pixel 5 spoof to Pixel 10 Pro spoof
* ability to install custom LineageOS build that contains new fake wifi implementation (thanks ayesa)
* fake wifi config automatically enabled for PvZ 2
* latest ATV13 builds (thanks supechicken)
* workaround for small var partition in SteamOS - ability to use libhoudini
* libhoudini as default translation layer instead of libndk for greater compatibility (pokemon, arknights, fire emblem etc are working) (thanks gagantous for the initial testing)
* fix for intermittent broken internet
* k2er, mantis, shizuku automatic activation
* CoD Mobile controller support (thanks Wudi-ZhanShen)

thanks to waydroid devs, ayesa, supechicken, Wudi-ZhanShen, gagantous and casualsnek!

<details>
<summary><b>Old Changelog - Click here for more details</b></summary>

**What's New (as of Nov 15 2025)**
1. Xbox Wireless Controller spoofing so that Call of Duty CoD Mobile works with the Steam Deck controller
2. Fixed low audio on fresh install
3. Latest StevenBlack adblock host file automatically downloaded during install
4. Added logic to the shizuku and mantis activation
5. Improved Decky Loader sanity check
6. Implemented logging
7. Refactored the python script that adds the waydroid icon for easy readability of the script
8. Updated uninstall

**What's New (as of July 28 2025)**
1. Sanity check updated - instead of kernel version check it will check if running on SteamOS stable / SteamOS beta
2. Auto build the binder kernel module
3. Cleanup and remove traces of A11. Available options to choose - A13 GAPPS, A13 NO_GAPPS, ATV13 NO_GAPPS
</details>

# Install Steps
<details>
<summary><b>Click here for original SteamOS install steps</b></summary>

**Prerequisites for SteamOS**
1. `sudo` password should already be set by the end user.

**How to Use and Install the Script**
1. Go into Desktop Mode and open a `konsole` terminal.
2. Clone the github repo.
   ```sh
   cd ~/
   git clone --depth=1 https://github.com/ryanrudolfoba/steamos-waydroid-installer
   ```
3. Execute the script!
   ```sh
   cd ~/steamos-waydroid-installer
   chmod +x steamos-waydroid-installer.sh
   ./steamos-waydroid-installer.sh
   ```
</details>

# Games Tested By ryanrudolfoba on Android Waydroid Steam Deck
[Plants vs Zombies](https://youtu.be/rnb0z1LtDN8) - Feb 04 2024 \
[Honkai Star Rail](https://youtu.be/M1Y9DMG9rbM) - Feb 06 2024 \
[Asphalt 8 Airborne](https://youtu.be/OCaatZdZR1I) - Feb 08 2024 \
[Honkai Impact 3rd](https://youtu.be/6YdNOJ0u2KM) - Feb 10 2024 \
[Mobile Legends](https://youtu.be/PlPRNn92NDI) - Feb 13 2024 \
[Roblox](https://youtu.be/-czisFuKoTM?si=8EPXyzasi3no70Tl) - May 01 2024 \
[Wuthering Waves](https://youtu.be/KfQVCTtpiNI) - May 23 2024

# Games Tested by Other Users
Please check this [google sheets](https://docs.google.com/spreadsheets/d/1pyqQw2XKJZBtGYBV0i7C510dyjVSU2YndhaTOEDavdU/edit?usp=sharing) for games tested by other users.