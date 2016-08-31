#!/bin/bash


echo "Cloning android-simg2img and super-bootimg forks into parent directory..."

cd ..


if [ ! -d ./android-simg2img ]
then
  git clone -b verity_tools3 https://github.com/mikeperry-tor/android-simg2img
  cd android-simg2img
  make
  cd ..
fi

if [ ! -d ./super-bootimg ]
then
  git clone -b verity_fix https://github.com/mikeperry-tor/super-bootimg
fi
