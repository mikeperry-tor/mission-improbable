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
echo "Please reboot phone into system. You can skip the Google Account Setup,"
echo "but don't forget to set the clock properly or Orbot won't work."
echo -n "[Hit Enter to continue...]"
read junk
