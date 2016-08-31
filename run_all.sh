#!/bin/bash

set -e

if [ $# -ne 5 ]
then
  echo "Usage: $0 <copperhead_factory_dir> <superboot_dir> <simg2img_dir> <twrp_image> <gapps.zip>"
  exit 1
fi

COPPERHEAD_DIR=$1
SUPERBOOT_DIR=$2
SIMG2IMG_DIR=$3
TWRP_IMG=$4
GAPPS_ZIP=$5

./clone-helper-repos.sh
./fetch-apks.sh

if [ ! -f ./keys/verity_key.pub ];
then
  cd keys
  ./make_keys.sh
  cd -
fi

./install-copperhead.sh $COPPERHEAD_DIR
./install-su.sh $COPPERHEAD_DIR $SUPERBOOT_DIR

./install-gapps.sh $TWRP_IMG $GAPPS_ZIP
./re-sign.sh $COPPERHEAD_DIR $SIMG2IMG_DIR

./flash-signed.sh

./install-packages.sh

echo
echo "All done! Yay!"
