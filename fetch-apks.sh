#!/bin/bash
# vim:ts=2 sw=2 sts=2 expandtab:

if [ $NO_TOR -eq 1 ]; then
  APPS=( $(grep -Ev "^[[:space:]]*([#]|$)" apk_url_list.txt | grep -Ev 'orwall|orbot') )
  for REMOVE in orwall orbot; do
    rm -f packages/*${REMOVE}*.apk
    rm -f packages/*${REMOVE}*.apk.asc
  done
else
  APPS=( $(grep -Ev "^[[:space:]]*([#]|$)" apk_url_list.txt) )
fi

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
ln -sf gapps-delta-arm64-7.1-nano-20170127.tar.xz gapps-delta.tar.xz

cd -
