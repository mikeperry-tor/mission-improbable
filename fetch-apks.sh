#!/bin/bash

APPS=( $(cat apk_url_list.txt) )

set -e

cd packages

for i in $(seq 0 $((${#APPS[@]} - 1)))
do
  if [ ! -f `basename ${APPS[$i]}` ]
  then
    wget -U "" ${APPS[$i]}
  fi
done

for i in *.asc
do
  gpg --homedir=. --no-default-keyring --keyring=gpgkeys.keyring $i
done

# XXX: hrmm.. this is pretty dirty...
ln -sf gapps-delta-arm64-7.1-micro-20170129.tar.xz gapps-delta.tar.xz

cd -
