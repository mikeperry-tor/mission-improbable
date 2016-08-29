#!/bin/bash

set -e

if [ $# -ne 4 ]
then
  echo "Usage: $0 <copperhead_factory_dir> <superboot_dir> <twrp_image> <gapps.zip>"
  exit 1
fi

COPPERHEAD_DIR=$1
SUPERBOOT_DIR=$2
TWRP_IMG=$3
GAPPS_ZIP=$4

./install-copperhead.sh $COPPERHEAD_DIR
./install-su.sh $COPPERHEAD_DIR $SUPERBOOT_DIR

./install-gapps.sh $TWRP_IMG $GAPPS_ZIP
./re-sign.sh $COPPERHEAD_DIR

./flash-signed.sh
