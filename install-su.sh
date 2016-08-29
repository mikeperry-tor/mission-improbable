#!/bin/bash
set -e

if [ ! -d "$1" -o ! -s "$2" ]
then
  echo "Usage: $0 <copperhead_factory_directory> <super-bootimg_dir>"
  exit 1
fi

COPPERHEAD_DIR=$1
SUPERBOOT_DIR=$2

pushd $COPPERHEAD_DIR

mkdir -p images
cd images

if [ ! -f "boot.img" ]
then
  unzip ../*.zip
fi

popd

cp $COPPERHEAD_DIR/images/boot.img $SUPERBOOT_DIR/scripts/boot.img

cd $SUPERBOOT_DIR/scripts
./bootimg.sh boot.img
cd -

cp $SUPERBOOT_DIR/scripts/new-boot.img.signed ./images/boot-signed.img


