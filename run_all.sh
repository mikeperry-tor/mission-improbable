#!/bin/bash

set -e

if [ $# -lt 2 ]; then
  echo "Usage: $0 <copperhead_factory_dir> <device> [<options>]"
  echo "Options: [ --spoof | enables signature spoofing ]"
  echo "[ --[<package>] | installs the specified OpenGApps package ]"
  echo "[ --twrp | flashes TWRP recovery to the device ]"
  echo "[ --update | updates current system, don't use both GApps and this ]"
  echo "Devices: angler | bullhead"
  echo "Packages: see www.opengapps.org"
  exit 1
fi

COPPERHEAD_DIR=$1
DEVICE=$2
SUPERBOOT_DIR=$PWD/helper-repos/super-bootimg
SIMG2IMG_DIR=$PWD/helper-repos/android-simg2img
OPENLIST="aroma super stock full mini micro nano pico"

./clone-helper-repos.sh $SUPERBOOT_DIR $SIMG2IMG_DIR
./fetch-apks.sh

if [ ! -f ./keys/verity_key.pub ]; then
  cd keys
  ./make_keys.sh $SIMG2IMG_DIR
  cd -
fi

if [[ "$@" = "--update" ]]; then
  ./update.sh
else
  ./install-copperhead.sh $COPPERHEAD_DIR
  ./install-su.sh $COPPERHEAD_DIR $SUPERBOOT_DIR
  ./re-sign.sh $COPPERHEAD_DIR $SIMG2IMG_DIR $SUPERBOOT_DIR
  ./flash-signed.sh
  ./install-packages.sh
fi

if [[ "$@" = "--twrp" ]]; then
  TWRP=true
  fastboot flash recovery twrps/twrp-*-${DEVICE}.img
fi

for i in "${OPENLIST[@]}"
do
    if [[ "$i" == "$@" ]] ; then
      PACKAGE=$i
      wget "https://github.com/opengapps/arm64/releases/download/20161129/open_gapps-arm64-7.0-${PACKAGE}-20161129.zip"
      if [ $TWRP ]; then
	fastboot reboot-recovery
	adb sideload open_gapps-*.zip
      else
	fastboot flash recovery twrp-*-${DEVICE}.img
	fastboot reboot-recovery
	adb sideload open_gapps-*.zip
	adb reboot-bootloader
	fastboot flash recovery $COPPERHEAD_DIR/recovery.img
      fi
    fi
done

if [[ "$@" = "--spoof" ]]; then
  while true; do
      echo "To spoof signatures, you need root on the device or TWRP installed!"
      echo "Java, Python and ADB are also required! I highly recommend booting into TWRP!"
      read -p "Are you sure you want to enable signature spoofing? (y/n)" yn
      case $yn in
          [Yy]* ) echo "You have been warned, proceeding..."; ./spoof-signatures.sh;;
          [Nn]* ) echo "Smart man, skipping..."; break;;
          * ) echo "Please answer y or n.";;
      esac
  done
else
  echo "Skipping signature spoofing."
fi

echo
echo "All done! Yay!"
