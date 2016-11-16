#!/bin/sh

SIMG2IMG_DIR=$1

../extras/make_key verity '/C=CA/ST=Ontario/L=Toronto/O=CopperheadOS/OU=CopperheadOS/CN=CopperheadOS/emailAddress=copperheados@copperhead.co'
$SIMG2IMG_DIR/generate_verity_key -convert verity.x509.pem verity_key

../extras/make_key releasekey '/C=CA/ST=Ontario/L=Toronto/O=CopperheadOS/OU=CopperheadOS/CN=CopperheadOS/emailAddress=copperheados@copperhead.co'
java -jar ../extras/blobs/dumpkey.jar ./releasekey.x509.pem > release_key
