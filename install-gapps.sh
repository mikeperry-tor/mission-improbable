#!/bin/bash

set -e

if [ ! -f "$1" -o ! -f "$2" ]
then
  echo "Usage: $0 <twrp_image> <gapps.zip>"
  exit 1
fi

TWRP_IMAGE=$1
GAPPS_ZIP=$2
# XXX: Make this an arg?
SIMG2IMG_DIR=$PWD/helper-repos/android-simg2img

echo
echo "Ensure the fastboot bootloader is ready."
echo -n "[Hit Enter to continue...]"
read junk

fastboot flashing unlock || true

echo
echo "Ensure flashing is unlocked."
echo -n "[Hit Enter to continue...]"
read junk

fastboot flash recovery $TWRP_IMAGE

echo
echo "Please reboot into recovery and swipe to start adb sideload (under Advanced)."
echo "You do not need to allow modifications to /system (keep it read-only)"
echo
echo "If the recovery tries to reboot due to an error, do not let the system"
echo "boot! Reboot into the bootloader immediately and enter recovery again."
echo "(Otherwise, OpenGapps won't install properly)."
echo -n "[Hit Enter to continue...]"
read junk

# Bleh. Sometimes you need to plug the device in again..
if [ -z "$(adb devices | grep sideload)" ]
then
  echo
  echo "You need to unplug and replug your device after starting sideload.."
  echo -n "[Hit Enter to continue...]"
  read junk
fi

adb sideload $GAPPS_ZIP

if [ -z "$(adb devices | grep recovery)" ]
then
  echo
  echo "Ensure recovery screen is not locked (swipe to unlock)."
  echo "You may need to unplug and replug your device again..."
  echo -n "[Hit Enter to continue...]"
  read junk
fi

adb pull /dev/block/platform/soc.0/f9824900.sdhci/by-name/system ./images/system.img.raw

echo
echo "We now need sudo to extract a delta of the gapps files for future updates"

mkdir -p ./images/system
mkdir -p ./images/system.orig

$SIMG2IMG_DIR/simg2img ./images/system.img ./images/system.img.orig

sudo mount -o ro ./images/system.img.raw ./images/system/
sudo mount -o ro ./images/system.img.orig ./images/system.orig/

# Create filelist and deletion list
cd images
sudo ../extras/added-changed-removed.py ./system.orig/ ./system/
sudo mv added-or-changed-files ../gapps_filelist.txt
sudo mv removed-files ../gapps_removelist.txt
owner=$(whoami)
sudo chown $owner ../gapps_filelist.txt ../gapps_removelist.txt

sudo tar -Jcvf ../packages/gapps-delta.tar.xz --selinux --files-from ../gapps_filelist.txt
sudo umount system
sudo umount system.orig
