## Copperhead Tor Phone Prototype

The scripts in this directory help you create your own rooted Tor-enabled
gapps capable Copperhead image that is signed with your own keys for verified
boot.

## Prerequisites

You need a recent fastboot and adb from the command line tools package at the
bottom of https://developer.android.com/studio/index.html#downloads. The ones
in Debian/stable are sadly too old :(. You can tell if yours is recent enough
if fastboot supports the "fastboot flashing unlock" command.

You also need a Java JRE/JDK 1.7 or higher, git, gcc, g++, and openssl
development packages (libssl-dev or openssl-devel).

Your phone also will need to have OEM Unlocking enabled from the "Developer
Options" menu in order to unlock fastboot. Go to Settings->About Phone and
click on Build Number 5 times to enable Developer Options. The Developer
Options menu will appear in Settings, and the OEM Unlocking switch is present
there.

You need some other things, too, but the scripts will download them for you.
Run ./run_all.sh with torsocks if you want to fetch that stuff via Tor.

## Instructions

There are a ton of scripts in here. Eventually, we want to make it possible to
choose if you want Google Apps, SuperUser, Tor, or some subset. For now, the
best thing to do is just run ./run_all.sh. The script should walk you through
everything, printing out instructions (and command output) as it goes. It will
halt on any error, but you can re-run it from the top or run pieces of it
individually.

Here is an example (after you have downloaded the angler factory image from
https://copperhead.co/android/downloads and its signature and placed it in
this directory):

~~~~
$ gpg angler-factory-2016.10.27.20.13.46.tar.xz.sig
$ tar -Jxvf angler-factory-2016.10.27.20.13.46.tar.xz
$ ./run_all.sh angler-nbd90z ./helper-repos/
~~~~

This installation script will generate device keys in the keys directory of
the filesystem. You will need these keys to update the phone. Keep them safe,
and do not lose them.

To update your phone, download a new Copperhead Factory Image from website,
and install it with update.sh. Make sure you have your device keys in the
keys subdirectory directory. Then run:

~~~~
$ gpg angler-factory-2016.10.27.20.13.46.tar.xz.sig
$ tar -Jxvf angler-factory-2016.10.27.20.13.46.tar.xz
$ ./update.sh angler-nbd90z ./helper-repos/ angler
~~~~

## Binary blobs that run on the host machine

The following is a list of binary blobs we run on your machine during build.
(XXX: Find and link to the sources for these).

* ./extras/blobs/dumpkey.jar
* ./extras/blobs/signapk.jar
* ./extras/blobs/VeritySigner.jar
* ../super-bootimg/scripts/bin/bootimg-extract
* ../super-bootimg/scripts/bin/bootimg-repack
* ../super-bootimg/scripts/bin/sepolicy-inject
* ../super-bootimg/scripts/bin/strip-cpio

## Binary blobs that run on the phone

* ./extras/blobs/update-binary
* ../super-bootimg/scripts/bin/su-arm
* ./packages/gapps-delta.tar.xz (OpenGapps Pico)

## TODOs and Future Work

* We should probably have a script that does some dependency checking and
helps the user install stuff they need to build and install everything.

* The update process only supports angler (Nexus 6P) right now. Once
  Copperhead supports the newer Pixel devices, we'll try to add those.

* We should support the new Nougat FECC layer on top of Verity. Right now, we
  leave it out.
  (https://android-developers.blogspot.com/2016/07/strictly-enforced-verified-boot-with.html)

* If we wanted to support more opengapps than pico, we could generate the
gapps file list on the fly.

* We should build or replace as many of the binary blobs as we can. For some
things, this is very tricky, since they have dependencies across the android
tree.

* Instead of OpenGapps, it might be nice to provide the MicroG builds: https://microg.org/. This requires some hackery to spoof the Google Play Service Signature field, though: https://github.com/microg/android_packages_apps_GmsCore/wiki/Signature-Spoofing. Unfortunately, this method creates a permission that any app can request to spoof signatures for any service. I'd be much happier about this if we could find a way for MicroG to be the only app to be able to spoof permissions, and only for the Google services it was replacing.

* Right now, we require superuser, since the super-bootimg scripts are used to
sign the boot partition and ensure verified boot. This is not ideal, since
those scripts depend on some binary blobs in that repository (see below), and
also because some people might just want Gapps and not Root+Tor.

* We also need root right now to edit the ext4 images by mounting them.
Technically we could use make_ext4fs from the Android build tree, but it
requires a block map, file permission lists, and selinux context lists. We
would need some other tool to extract (or keep copies of) those..

* Back in the WhisperCore days, Moxie wrote a Netfilter module using libiptc
that enabled apps to edit iptables rules if they had permissions for it. This
would eliminate the need for root and crazy iptables shell callouts for using
OrWall. This should be more stable and less leaky than the current VPN apis.

## Bugs

1. The swipe keyboard driver is not being recognized by Copperhead's LatinIME
package due to the build pref
https://github.com/CopperheadOS/platform_packages_inputmethods_LatinIME/blob/marshmallow-mr2-release/java/res/values/gesture-input.xml.
We need to do a test build and ensure that flipping that pref won't spam logs,
cause issues, or have library search path issues for stock users.

2. The bootup script [stopped working](https://github.com/EthACKdotOrg/orWall/issues/121) with Orwall
1.2.0. We have to use Orwall 1.1.0. Do not upgrade to 1.2.0 or networking will
break.
