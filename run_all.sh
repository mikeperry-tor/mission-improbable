#!/bin/bash

set -e

if [ $# -ne 1 -a $# -ne 3 ]
then
  echo "Usage: $0 <copperhead_factory_dir> [<gapps.zip>] [<twrp.img>]"
  exit 1
fi

COPPERHEAD_DIR=$1
SUPERBOOT_DIR=$PWD/helper-repos/super-bootimg
SIMG2IMG_DIR=$PWD/helper-repos/android-simg2img
GAPPS_ZIP=$2
TWRP_IMG=$3

./clone-helper-repos.sh $SUPERBOOT_DIR $SIMG2IMG_DIR
./fetch-apks.sh

if [ ! -f ./keys/verity_key.pub ];
then
  cd keys
  ./make_keys.sh $SIMG2IMG_DIR
  cd -
fi

./install-su.sh $COPPERHEAD_DIR $SUPERBOOT_DIR

if [ ! -f "$TWRP_IMG" -o ! -f "$GAPPS_ZIP" ];
then
  ./apply-gapps-delta.sh $COPPERHEAD_DIR $SIMG2IMG_DIR
else
  # XXX: Ok to run after install-su.sh?
  ./install-copperhead.sh $COPPERHEAD_DIR
  ./install-gapps.sh $TWRP_IMG $GAPPS_ZIP
fi

./re-sign.sh $COPPERHEAD_DIR $SIMG2IMG_DIR $SUPERBOOT_DIR

./flash-signed.sh

./install-packages.sh

echo
echo "All done! Yay!"
