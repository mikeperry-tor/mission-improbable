#!/bin/bash

set -e

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
