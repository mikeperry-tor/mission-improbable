#!/bin/bash

set -e

if [ ! -d "$1" ]
then
  echo "Usage: $0 <copperhead_factory_directory>"
  exit 1
fi

COPPERHEAD_DIR=$1

echo
echo "Please reboot into the fastboot bootloader and hit enter"
read junk

cd $COPPERHEAD_DIR

fastboot flashing unlock || true
sleep 5

echo
echo "Ensure flashing is unlocked and hit enter"
read junk

./flash-base.sh

mkdir -p images
cd images

if [ ! -f "boot.img" ]
then
  unzip ../*.zip
fi

for i in *.img
do
  fastboot flash `basename $i .img` $i
done

cd ..

echo
echo "Copperhead successfully installed!"
