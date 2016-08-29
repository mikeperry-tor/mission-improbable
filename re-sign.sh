#!/bin/bash

set -e

ANDROID_BUILD_ROOT=/mnt/android/copperheados-marshmallow-dr1.6-signingtoolsonly/
TOOL_PATH=$ANDROID_BUILD_ROOT/out/host/linux-x86/bin/
EXTRAS_PATH=$ANDROID_BUILD_ROOT/system/extras/verity/
JAR_PATH=$ANDROID_BUILD_ROOT/out/host/linux-x86/framework/

if [ ! -d "$1" ]
then
  echo "Usage: $0 <copperhead_factory_directory>"
  exit 1
fi

if [ ! -f "images/boot-signed.img" ]
then
  echo "You must currently install su in order to get verified boot..."
  echo "(XXX: This is only because we have not implented boot.img signing)"
  exit 1
fi

COPPERHEAD_DIR=$1

cp $COPPERHEAD_DIR/images/*.img ./images/
cd images

if [ ! -f "system.img.raw" ]
then
  $TOOL_PATH/simg2img system.img system.img.raw
fi


echo "We now need sudo to install the OrWall startup script..."
mkdir -p system
sudo mount system.img.raw system
sudo cp ../orwall-userinit.sh system/bin/oem-iptables-init.sh
# system/sbin/svc has u:object_r:system_file:s0, which is convenient since
# the host selinux may not understand that context
sudo chcon --reference=system/bin/svc system/bin/oem-iptables-init.sh
sudo chmod 755 system/bin/oem-iptables-init.sh
sudo umount system

SYSTEM_SIZE=$($TOOL_PATH/ext2simg -v system.img.raw system-signed.img | grep "Size: " | cut -d: -f2)

rm -f verity*

SYSTEM_ROOT_HASH=$($TOOL_PATH/build_verity_tree -A aee087a5be3b982978c923f566a94613496b417f2af592639bc80d141e34dfe7 system-signed.img verity.img)

$EXTRAS_PATH/build_verity_metadata.py $SYSTEM_SIZE verity_metadata.img $SYSTEM_ROOT_HASH /dev/block/platform/soc.0/f9824900.sdhci/by-name/system $TOOL_PATH/verity_signer $ANDROID_BUILD_ROOT/keys/verity.pk8

$TOOL_PATH/append2simg system-signed.img verity_metadata.img
$TOOL_PATH/append2simg system-signed.img verity.img

# For Vendor

$TOOL_PATH/simg2img vendor.img vendor-unsigned.img.raw
VENDOR_SIZE=$($TOOL_PATH/ext2simg -v vendor-unsigned.img.raw vendor-signed.img | grep "Size: " | cut -d: -f2)

#$TOOL_PATH/img2simg vendor-unsigned.img.raw vendor-signed.img
#./android-simg2img/simg_trunc vendor.img vendor-signed.img

rm -f verity*

VENDOR_ROOT_HASH=$($TOOL_PATH/build_verity_tree -A aee087a5be3b982978c923f566a94613496b417f2af592639bc80d141e34dfe7 vendor-signed.img verity.img)

$EXTRAS_PATH/build_verity_metadata.py $VENDOR_SIZE verity_metadata.img $VENDOR_ROOT_HASH /dev/block/platform/soc.0/f9824900.sdhci/by-name/vendor $TOOL_PATH/verity_signer $ANDROID_BUILD_ROOT/keys/verity.pk8

$TOOL_PATH/append2simg vendor-signed.img verity_metadata.img
$TOOL_PATH/append2simg vendor-signed.img verity.img

# For Recovery: XXX: No good. Need to also replace verity_key, but a resigned
# recovery is not really needed at all at this point.
#java -jar $JAR_PATH/BootSignature.jar /boot recovery.img $ANDROID_BUILD_ROOT/keys/verity.pk8 $ANDROID_BUILD_ROOT/keys/verity.x509.pem recovery-signed.img

# For Boot: XXX No good. Need to also replace verity_key (super-bootimg does
# this for now)
#java -jar $JAR_PATH/BootSignature.jar /boot boot.img $ANDROID_BUILD_ROOT/keys/verity.pk8 $ANDROID_BUILD_ROOT/keys/verity.x509.pem boot-signed.img
