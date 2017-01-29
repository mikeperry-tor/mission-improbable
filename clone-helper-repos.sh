#!/bin/bash

set -e

echo "Cloning android-simg2img and super-bootimg forks..."

SUPERBOOT_DIR=$1
SIMG2IMG_DIR=$2

if [ ! -d $SIMG2IMG_DIR ]
then
  git clone -b verity_tools3 https://github.com/mikeperry-tor/android-simg2img $SIMG2IMG_DIR
fi

# XXX: Maybe update git here?
cd $SIMG2IMG_DIR
make
cd -

# XXX: Should add something to check for a different origin/branch/checkout and fix it
if [ ! -d $SUPERBOOT_DIR ]
then
  git clone -b verity_fix-nougat https://github.com/mikeperry-tor/super-bootimg $SUPERBOOT_DIR
fi
