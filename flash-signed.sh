#!/bin/bash

set -e

echo
echo "Please ensure the device is in the fastboot bootloader."
echo -n "[Hit Enter to continue...]"
read junk

fastboot flashing unlock || true

echo
echo "Ensure flashing is unlocked."
echo -n "[Hit Enter to continue...]"
read junk

fastboot flash recovery ./images/recovery-signed.img
fastboot flash system ./images/system-signed.img
fastboot flash boot ./images/boot-signed.img
fastboot flash vendor ./images/vendor-signed.img
fastboot flashing lock

echo
echo "Please reboot phone into system.  The first boot can take several minutes, be patient."
echo

if [ $NO_TOR -eq 0 ]; then
  echo "Remember to set the clock properly or Orbot won't work."
  echo
fi

echo -n "[Hit Enter to continue...]"
read junk
