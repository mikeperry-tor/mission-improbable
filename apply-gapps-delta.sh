#!/bin/bash

set -e

if [ ! -f "./packages/gapps-delta.tar.xz" ]
then
  echo "Need a Google Apps Delta from a previous install.."
  exit 1
fi

if [ ! -d "$1" -o ! -d "$2" ]
then
  echo "Usage: $0 <copperhead_factory_directory> <android-simg2img_dir>"
  exit 1
fi

COPPERHEAD_DIR=$1
TOOL_PATH=$(readlink -f $2)

cd $COPPERHEAD_DIR
mkdir -p images
cd images
if [ ! -f "boot.img" ]
then
  unzip ../*.zip
fi
cd ../../

mkdir -p images/system

$TOOL_PATH/simg2img $COPPERHEAD_DIR/images/system.img ./images/system.img.raw

echo "We now need sudo to mount the system image and apply the delta"

sudo mount ./images/system.img.raw ./images/system
cd images
# Remove old files that opengapps removes (sort -r ensures parent directories are
# deleted last)
for file in `sort -r ../gapps_removelist.txt`
do
  if [ -d $file ]; then
    sudo rm -fd $file
  else
    sudo rm -f $file
  fi
done

sudo tar --selinux -Jxvf ../packages/gapps-delta.tar.xz
sudo umount ./system
cd ..

echo "Gapps delta applied!"
