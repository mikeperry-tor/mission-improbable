#!/bin/bash

set -e

echo
echo "Please reboot into the fastboot bootloader and hit enter"
read junk

fastboot flashing unlock || true

echo
echo "Ensure flashing is unlocked and hit enter"
read junk

if [ -f "./images/recovery-signed.img" ]
then
  fastboot flash recovery ./images/recovery-signed.img
else
  fastboot flash recovery ./images/recovery.img
fi

fastboot flash system ./images/system-signed.img
fastboot flash boot ./images/boot-signed.img
fastboot flash vendor ./images/vendor-signed.img
fastboot flashing lock

echo
echo "Please rebooting phone into system. If you installed gapps, it will keep crashing"
echo "until you give Google Play Services the location and storage permissions."
echo "(under settings->Apps->Google Play Services->Permissions)."
echo "Just click through the setup screen until you get past it to get into settings."
read junk
