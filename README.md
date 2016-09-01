## Copperhead Tor Phone Prototype

The pile of scripts in this directory help you create your own rooted
Tor-enabled gapps capable Copperhead image that is signed with your own keys
for verified boot.

WARNING: Until we have a re-signed recovery with a custom release key, updates
to the copperhead OS will not be possible without a full re-flash. Since
verified boot is enabled, this will require a factory reset! This will be true
for all devices initially installed *without* a re-signed recovery image, even
if one becomes available later. See TODOs for more info.

## Prerequisites

You need a recent fastboot and adb from the command line tools package at the
bottom of https://developer.android.com/studio/index.html#downloads. The ones
in Debian/stable are sadly too old :(. You can tell if yours is recent enough
if fastboot supports the "fastboot flashing unlock" command.

You also need a Java JRE/JDK 1.7 or higher.

You also need TWRP from https://dl.twrp.me/angler/ (or your device) and an
extracted Copperhead factory image from https://copperhead.co/android/downloads.

Finally, you need opengapps from https://opengapps.github.io/. The pico image
will work, if you only want Google Play Services and the Play store.

You need some other things, too, but the scripts will download them for you.
Run ./run_all.sh with torsocks if you want to fetch that stuff via Tor.

## Instructions

There are a ton of scripts in here. Eventually, we want to make it possible to
choose if you want Google Apps, SuperUser, Tor, or some subset. For now, the
best thing to do is just run ./run_all.sh.

## TODOs

* Right now, we require superuser, since the super-bootimg scripts are used to
sign the boot partition and ensure verified boot. This is not ideal, since
those scripts depend on some binary blobs in that repository, and also because
some people might just want Gapps and not Root+Tor.

* We also depend on a binary blob for VeritySigner.jar, since building
bouncycastle and the associated Java signer outside the android build tree
is painful.

* Eventually, we also should re-sign the recovery image and include a new
release key, so that self-signed updates can be performed via sideload. Until
this is done, this does mean that devices that were installed without a
re-signed recovery will require a factory reset to update, because we have
to unlock again to flash from fastboot!

* We should also remove the requirement for TWRP by creating gapps install
scripts to install gapps from the host OS, rather than on the device. This
will simplify installation quite a bit. Alternatively, we could re-sign the
gapps zip with our own release key so that it could be sideloaded into
our modified and re-signed Copperhead recovery (instead of TWRP).

## Future Work

* Instead of OpenGapps, it might be nice to provide the MicroG builds:
https://microg.org/. This requires some hackery to spoof the Google Play
Service Signature field, though...

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

2. The bootup script stopped working with Orwall 1.2.0. We have to use Orwall
1.1.0. Do not upgrade to 1.2.0 or networking will break.


