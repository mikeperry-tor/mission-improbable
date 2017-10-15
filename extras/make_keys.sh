#!/bin/sh

set -e

REPO_ROOT="$(dirname $(dirname $(readlink -f "$0")))"
SIMG2IMG_DIR="$REPO_ROOT/helper-repos/android-simg2img"

cd "${REPO_ROOT}/keys"

"${REPO_ROOT}/extras/make_key" verity '/C=CA/ST=Ontario/L=Toronto/O=CopperheadOS/OU=CopperheadOS/CN=CopperheadOS/emailAddress=copperheados@copperhead.co'
"$SIMG2IMG_DIR/generate_verity_key" -convert verity.x509.pem verity_key

"${REPO_ROOT}/extras/make_key" releasekey '/C=CA/ST=Ontario/L=Toronto/O=CopperheadOS/OU=CopperheadOS/CN=CopperheadOS/emailAddress=copperheados@copperhead.co'

java -jar "${REPO_ROOT}/extras/blobs/dumpkey.jar" ./releasekey.x509.pem > release_key
