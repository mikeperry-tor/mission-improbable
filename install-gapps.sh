#!/bin/bash

set -e

if [ ! -f "$1" -o ! -f "$2" ]
then
  echo "Usage: $0 <twrp_image> <gapps.zip>"
  exit 1
fi

TWRP_IMAGE=$1
GAPPS_ZIP=$2

echo
echo "Please reboot into the fastboot bootloader and hit enter"
read junk

fastboot flashing unlock || true

echo
echo "Ensure flashing is unlocked and hit enter"
read junk

fastboot flash recovery $TWRP_IMAGE

echo
echo "Please reboot into recovery and swipe to start adb sideload (under Advanced)."
echo "You do not need to allow modifications to /system (keep it read-only)"
echo "Hit enter once you have started sideload from the recovery."
read junk

adb sideload $GAPPS_ZIP

echo
echo "Ensure recovery screen is not locked (swipe to unlock) and hit enter"
read junk

adb pull /dev/block/platform/soc.0/f9824900.sdhci/by-name/system ./images/system.img.raw

echo
echo "We now need sudo to extract a delta of the gapps files for future updates"

sudo mount ./images/system.img.raw ./images/system/
cd images
sudo tar -Jcvf gapps-delta.tar.xz --selinux --files-from ../gapps_filelist-6.0.txt
