#!/bin/bash

set -e

if [ $# -ne 1 -a $# -ne 3 -a $# -ne 2 -a $# -ne 4]; then
  echo "Usage: $0 <copperhead_factory_dir> [<options>] [<device>]"
  echo "Options: [ --spoof | enables signature spoofing ]"
  echo "[ --[<package>] | installs the specified OpenGApps package ]"
  echo "[ --twrp | flashes TWRP recovery to the device ]"
  echo "Devices: angler | bullhead"
  exit 1
fi

COPPERHEAD_DIR=$1
SUPERBOOT_DIR=$PWD/helper-repos/super-bootimg
SIMG2IMG_DIR=$PWD/helper-repos/android-simg2img

./clone-helper-repos.sh $SUPERBOOT_DIR $SIMG2IMG_DIR
./fetch-apks.sh

if [ ! -f ./keys/verity_key.pub ]; then
  cd keys
  ./make_keys.sh $SIMG2IMG_DIR
  cd -
fi

./install-copperhead.sh $COPPERHEAD_DIR
./install-su.sh $COPPERHEAD_DIR $SUPERBOOT_DIR
./re-sign.sh $COPPERHEAD_DIR $SIMG2IMG_DIR $SUPERBOOT_DIR
./flash-signed.sh
./install-packages.sh

if [ "$@" = "--twrp" ]; then
  TWRP=true
  wget --no-check-certificate "https://dl.twrp.me/${DEVICE}/twrp-3.0.2-2-${DEVICE}.img.html"
  fastboot flash recovery twrp-*.img
fi

for i in "${OPENLIST[@]}"
do
    if [ "$i" == "$@" ] ; then
	  PACKAGE=$i
      GAPPS=true
      wget --no-check-certificate "http://opengapps.org/?download=true&arch=arm64&api=7.0&variant=${PACKAGE}"
	  if [ $TWRP ]; then
		fastboot reboot-recovery
		adb sideload open_gapps-*.zip
	  else
	    fastboot flash recovery twrp-*.img
		fastboot reboot-recovery
		adb sideload open_gapps-*.zip
	  fi
    fi
done

if [ "$@" = "--spoof" ]; then
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
