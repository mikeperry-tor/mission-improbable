#!/bin/bash

set -e

usage() {
  echo "Usage: $0 -c <new_copperhead_factory_dir> -d <device_type> [--no-tor]"
  exit 1
}

# Use GNU getopt to capture arguments as it allows us to have long options
# which the bash builtin getopts doesn't support.  We also still support the
# old # positional arguments for now, but don't advertise them in the usage().
TEMP=$(getopt -o 'hc:d:T::' --long 'help,copperhead:,device:,no-tor::' -- "$@")
[ $? -ne 0 ] && usage
eval set -- "$TEMP"; unset TEMP
# Set defaults
NO_TOR=0
# Parse the args
while true; do
  case "$1" in
    '-c'|'--copperhead')
      COPPERHEAD_DIR=$2
      shift 2;
      continue
      ;;
    '-d'|'--device')
      DEVICE=$2
      shift 2
      continue
      ;;
    '-T'|'--no-tor')
      NO_TOR=1
      shift
      continue
      ;;
    '-h'|'--help')
      usage
      ;;
    '-*')
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    '--')
      shift
      break
      ;;
    *)
      POSITIONAL="$POSITIONAL $1"
      shift
      continue
      ;;
  esac
done

set +e
# Backwards compatibility for positional arguments
[ -z $COPPERHEAD_DIR ] && [ -n $1 ] && COPPERHEAD_DIR=$1 && shift
[ -z $DEVICE ] && [ -n $1 ] && DEVICE=$1 && shift
set -e

export COPPERHEAD_DIR
export DEVICE
export NO_TOR

# Bail out if no Copperhead directory was provided or no device defined
[ -z ${COPPERHEAD_DIR} ] && usage
[ -z ${DEVICE} ] && usage

SUPERBOOT_DIR=$PWD/helper-repos/super-bootimg
SIMG2IMG_DIR=$PWD/helper-repos/android-simg2img

#if [ ! -f "./packages/gapps-delta.tar.xz" ]
#then
#  echo "You have to have a gapps-delta zip from a previous install :("
#  exit 1
#fi

if [ ! -f "./extras/${DEVICE}/updater-script" ]
then
  echo "./extras/${DEVICE}/updater-script not found. Device unsupported?"
  exit 1
fi

cd $COPPERHEAD_DIR
mkdir -p images
cd images

if [ ! -f "boot.img" ]
then
  unzip ../*.zip
fi

cd ../..

./fetch-apks.sh
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
python ./extras/${DEVICE}/convert-factory.py $COPPERHEAD_DIR/radio-*.img $COPPERHEAD_DIR/bootloader-*.img ./update

cd update
mkdir -p META-INF/com/google/android/
mkdir -p META-INF/com/android/

cp ../extras/${DEVICE}/updater-script META-INF/com/google/android/updater-script
cp ../extras/${DEVICE}/update-binary META-INF/com/google/android/
cp ../extras/${DEVICE}/metadata META-INF/com/android

# XXX: bootloader.. not sure how to do that..

zip -r ../${DEVICE}-update.zip .

cd ..

java -jar ./extras/blobs/signapk.jar -w ./keys/releasekey.x509.pem ./keys/releasekey.pk8 ${DEVICE}-update.zip ${DEVICE}-update-signed.zip

echo
echo "Now please reboot your device into recovery:"
echo "  1. Reboot into Fastboot with Power + Volume Down"
echo "  2. Use Volume Down to select Recovery, and press Power"
echo "  3. Briefly tap Power + Volume-Up to get past the broken android logo."
echo -n "[Hit Enter to continue...]"
read junk
echo "Now select 'Apply Update from ADB' with Volume Down, and press Power."
echo -n "[Hit Enter to continue...]"
read junk

if [ -z "$(adb devices | grep sideload)" ]
then
  echo
  echo "You need to unplug and replug your device after starting sideload.."
  echo -n "[Hit Enter to continue...]"
  read junk
fi

adb sideload ${DEVICE}-update-signed.zip

echo
echo "All done! Yay! Select Reboot into System and press power."
