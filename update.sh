#!/bin/bash

set -e

if [ $# -ne 2 ]
then
  echo "Usage: $0 <new_copperhead_factory_dir> <device_type>"
  exit 1
fi

COPPERHEAD_DIR=$1
DEVICE=$2

cd $COPPERHEAD_DIR
./flash-base.sh
mkdir -p images
cd images

if [ ! -f "boot.img" ]
then
  unzip ../*.zip
fi

fastboot -w update ../*.zip

cd ../..

