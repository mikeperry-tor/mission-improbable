#!/bin/bash
dep=true
tools=true
packages="java git openssl python cpio gcc g++"
for package in $package; do
    command -v $package >/dev/null 2>&1 || { dep=false; }
done    
command -v adb >/dev/null 2>&1 || { tools=false; }
command -v fastboot >/dev/null 2>&1 || { tools=false; }
if [ "$tools" = "false" ]; then
  while true; do
      echo "ADB/Fastboot are missing!"
      read -p "Would you like to install now? (y/n)" yn
      case $yn in
          [Yy]* ) echo "This will require sudo..."; sudo cp extras/blobs/{adb,fastboot} /usr/local/bin;;
          [Nn]* ) echo "Aborting..."; break;;
          * ) echo "Please answer y or n.";;
      esac
  done
fi
if [ "$dep" = "false" ]; then
  while true; do
      echo "One or more packages is missing!"
      read -p "Would you like to install now? (y/n)" yn
      case $yn in
          [Yy]* ) echo "This will require sudo..."; sudo apt-get install -qq default-jre python libssl-dev;;
          [Nn]* ) echo "Aborting..."; break;;
          * ) echo "Please answer y or n.";;
      esac
  done
fi
