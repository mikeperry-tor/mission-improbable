#!/bin/bash

set -e

if [ $# -ne 3 ]
then
  echo "Usage: $0 <new_copperhead_factory_dir> <helper_dest_dir> <device_type>"
  exit 1
fi

COPPERHEAD_DIR=$1
SUPERBOOT_DIR=$2/super-bootimg
SIMG2IMG_DIR=$2/android-simg2img
DEVICE=$3

if [ ! -f "./packages/gapps-delta.tar.xz" ]
then
  echo "You have to have a gapps-delta zip from a previous install :("
  exit 1
fi

if [ ! -f "./extras/${DEVICE}/updater-script" ]
then
  echo "./extras/${DEVICE}/updater-script not found. Device unsupported?"
  exit 1
fi

echo "WARNING: This update script may contain bugs."
echo "Proceed at your own risk!"
read junk

cd $COPPERHEAD_DIR
mkdir -p images
cd images

if [ ! -f "boot.img" ]
then
  unzip ../*.zip
fi

cd ../..

./install-su.sh $COPPERHEAD_DIR $SUPERBOOT_DIR

./apply-gapps-delta.sh $COPPERHEAD_DIR $SIMG2IMG_DIR
./re-sign.sh $COPPERHEAD_DIR $SIMG2IMG_DIR $SUPERBOOT_DIR

# We need to extract raw system, vendor images
$SIMG2IMG_DIR/simg2img ./images/system-signed.img ./images/system-signed.raw
$SIMG2IMG_DIR/simg2img ./images/vendor-signed.img ./images/vendor-signed.raw

mkdir -p update
cp ./images/system-signed.raw ./update/
cp ./images/vendor-signed.raw ./update/
cp ./images/boot-signed.img ./update/
cp ./images/recovery-signed.img ./update/
./extras/${DEVICE}/convert-factory.py $COPPERHEAD_DIR/radio-*.img $COPPERHEAD_DIR/bootloader-*.img ./update

cd update
mkdir -p META-INF/com/google/android/
mkdir -p META-INF/com/android/

cp ../extras/${DEVICE}/updater-script META-INF/com/google/android/updater-script
cp ../extras/blobs/update-binary META-INF/com/google/android/
cp ../extras/metadata META-INF/com/android

# XXX: bootloader.. not sure how to do that..

zip -r ../${DEVICE}-update.zip .

cd ..

java -jar ./extras/blobs/signapk.jar -w ./keys/releasekey.x509.pem ./keys/releasekey.pk8 ${DEVICE}-update.zip ${DEVICE}-update-signed.zip

echo
echo "Now please reboot your device into recovery:"
echo "  1. Reboot into Fastboot with Power + Volume Down"
echo "  2. Use Volume Down to select Recovery, and press Power"
echo "  3. Briefly tap Power + Volume-Up to get past the broken android logo."
read junk
echo "Now select 'Apply Update from ADB' with Volume Down, and press Power."
read junk

if [ -z "$(adb devices | grep sideload)" ]
then
  echo
  echo "You need to unplug and replug your device after starting sideload.."
  echo "Hit enter once you have started sideload from the recovery."
  read junk
fi

adb sideload ${DEVICE}-update-signed.zip

echo
echo "All done! Yay!"
