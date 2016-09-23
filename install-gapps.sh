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
echo "Ensure the fastboot bootloader is ready and hit enter."
read junk

fastboot flashing unlock || true

echo
echo "Ensure flashing is unlocked and hit enter"
read junk

fastboot flash recovery $TWRP_IMAGE

echo
echo "Please reboot into recovery and swipe to start adb sideload (under Advanced)."
echo "You do not need to allow modifications to /system (keep it read-only)"
echo
echo "If the recovery tries to reboot due to an error, do not let the system"
echo "boot! Reboot into the bootloader immediately and enter recovery again."
echo "(Otherwise, OpenGapps won't install properly)."
read junk

# Bleh. Sometimes you need to plug the device in again..
adb devices | grep sideload > /dev/null

if [ ! $? ]
then
  echo
  echo "You need to unplug and replug your device after starting sideload.."
  echo "Hit enter once you have started sideload from the recovery."
  read junk
fi

adb sideload $GAPPS_ZIP

adb devices | grep recovery > /dev/null
if [ ! $? ]
then
  echo
  echo "Ensure recovery screen is not locked (swipe to unlock) and hit enter."
  echo "You may need to unplug and replug your device again..."
  read junk
fi

adb pull /dev/block/platform/soc.0/f9824900.sdhci/by-name/system ./images/system.img.raw

echo
echo "We now need sudo to extract a delta of the gapps files for future updates"

mkdir -p ./images/system
sudo mount ./images/system.img.raw ./images/system/
cd images
sudo tar -Jcvf ../packages/gapps-delta.tar.xz --selinux --files-from ../gapps_filelist-7.0.txt
sudo umount system
