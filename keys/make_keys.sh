#!/bin/sh

../extras/make_key verity '/C=CA/ST=Ontario/L=Toronto/O=CopperheadOS/OU=CopperheadOS/CN=CopperheadOS/emailAddress=copperheados@copperhead.co'

../../android-simg2img/generate_verity_key -convert verity.x509.pem verity_key
