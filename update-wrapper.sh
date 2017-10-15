#!/bin/sh

set -e
[ ${DEBUG:=0} -ge 1 ] && set -x

DEVICE="${1}"
shift
TIMESTAMP=$(date +%F_%H%M%S)

cd "$(dirname "$0")"
[ -d log ] || mkdir log
./get-release-image.py "${DEVICE}" 2>&1 | tee "log/${TIMESTAMP}_get-release-image.log"

if grep -ql 'Found new factory image' "log/${TIMESTAMP}_get-release-image.log" >/dev/null; then
    tar -Jvxf $(awk -F: '/^Found new factory image.*\.xz$/ {print $2}' "log/${TIMESTAMP}_get-release-image.log") > "log/${TIMESTAMP}_${DEVICE}.log"
    ./update.sh --scheduled -d "${DEVICE}" -c $(head -n1 "log/${TIMESTAMP}_${DEVICE}.log" | sed 's/\///') $@ > "log/${TIMESTAMP}_update.log"
fi
