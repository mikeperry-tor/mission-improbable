## Copperhead Tor Phone Prototype

The pile of scripts in this directory help you create your own rooted
Tor-enabled gapps capable CopperHead image that is signed with your own keys
for verified boot.

## Prerequisites

You need a recent fastboot and adb from the command line tools package at the
bottom of https://developer.android.com/studio/index.html#downloads. The ones
in Debian/stable are sadly too old :(. You can tell if yours is recent enough
if fastboot supports the "fastboot flashing unlock" command.

You also need a Java JRE/JDK 1.7 or higher.

You also need TWRP from https://dl.twrp.me/angler/ (or your device) and an
extracted copperhead factory image from https://copperhead.co/android/downloads.

Finally, you need opengapps from https://opengapps.github.io/. The pico image
will work, if you only want Google Play Services and the Play store.

You need some other things, too, but the scripts will download them for you.
Run ./run_all.sh with torsocks if you want to fetch that stuff via Tor.

## Instructions

There are a ton of scripts in here. Eventually, we want to make it possible to
choose if you want Google Apps, SuperUser, Tor, or some subset. For now, the
best thing to do is just run ./run_all.sh.

## TODOs

Right now, we require superuser, since the super-bootimg scripts are used to
sign the boot partition and ensure verified boot. This is not ideal, since
those scripts depend on some binary blobs in that repository. We also depend
on a binary blob for VeritySigner.jar, since building bouncycastle and the
associated Java signer outside the android build tree is painful.

Eventually, we also should re-sign the recovery image and include a new
release key, so that self-signed updates can be performed via sideload.

## Bugs

1. The swipe keyboard driver is not being recognized by CopperHead's LatinIME
package for some reason.

2. The bootup script stopped working with Orwall 1.2.0. We have to use Orwall
1.1.0. Do not upgrade to 1.2.0 or networking will break.
