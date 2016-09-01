#!/bin/bash

set -e

EXTRAS_PATH=$(readlink -f ./extras/)
KEYS_PATH=$(readlink -f ./keys/)
IMAGES_PATH=$(readlink -f ./images/)

if [ ! -d "$1" -o ! -d "$2" -o ! -d "$3" ]
then
  echo "Usage: $0 <copperhead_factory_directory> <android-simg2img_dir> <superbootimg_dir>"
  exit 1
fi

if [ ! -f "images/boot-signed.img" ]
then
  echo "You must currently install su in order to get verified boot..."
  echo "(XXX: This is only because we have not implented boot.img signing)"
  exit 1
fi

COPPERHEAD_DIR=$1
TOOL_PATH=$(readlink -f $2)
SUPERBOOT_PATH=$(readlink -f $3)

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

$EXTRAS_PATH/build_verity_metadata.py $SYSTEM_SIZE verity_metadata.img $SYSTEM_ROOT_HASH /dev/block/platform/soc.0/f9824900.sdhci/by-name/system $EXTRAS_PATH/verity_signer ../keys/verity.pk8

$TOOL_PATH/append2simg system-signed.img verity_metadata.img
$TOOL_PATH/append2simg system-signed.img verity.img

# For Vendor

$TOOL_PATH/simg2img vendor.img vendor-unsigned.img.raw
VENDOR_SIZE=$($TOOL_PATH/ext2simg -v vendor-unsigned.img.raw vendor-signed.img | grep "Size: " | cut -d: -f2)

#$TOOL_PATH/img2simg vendor-unsigned.img.raw vendor-signed.img
#./android-simg2img/simg_trunc vendor.img vendor-signed.img

rm -f verity*

VENDOR_ROOT_HASH=$($TOOL_PATH/build_verity_tree -A aee087a5be3b982978c923f566a94613496b417f2af592639bc80d141e34dfe7 vendor-signed.img verity.img)

$EXTRAS_PATH/build_verity_metadata.py $VENDOR_SIZE verity_metadata.img $VENDOR_ROOT_HASH /dev/block/platform/soc.0/f9824900.sdhci/by-name/vendor $EXTRAS_PATH/verity_signer ../keys/verity.pk8

$TOOL_PATH/append2simg vendor-signed.img verity_metadata.img
$TOOL_PATH/append2simg vendor-signed.img verity.img

# For Recovery: XXX: Need to also replace verity_key, but a resigned
# recovery is not really needed at all at this point.

RECOVERYRAMDISK_DIR="$(mktemp -d)"
RECOVERYFILES_DIR="$(mktemp -d)"

cd $RECOVERYRAMDISK_DIR
$SUPERBOOT_PATH/scripts/bin/bootimg-extract $IMAGES_PATH/recovery.img

cd $RECOVERYFILES_DIR

gunzip -c "$RECOVERYRAMDISK_DIR"/ramdisk.gz | cpio -i
gunzip -c "$RECOVERYRAMDISK_DIR"/ramdisk.gz > ramdisk1

cp $KEYS_PATH/release_key ./res/keys
cp $KEYS_PATH/verity_key.pub ./verity_key
echo "res/keys verity_key" |tr ' ' '\n' | cpio -o -H newc > ramdisk2

rm -f cpio-*

$SUPERBOOT_PATH/scripts/bin/strip-cpio ramdisk1 res/keys verity_key
cat cpio-* ramdisk2 |gzip -9 -c > "$RECOVERYRAMDISK_DIR"/ramdisk.gz

cd $RECOVERYRAMDISK_DIR
rm -f cpio-*
$SUPERBOOT_PATH/scripts/bin/bootimg-repack $IMAGES_PATH/recovery.img

java -jar $SUPERBOOT_PATH/scripts/keystore_tools/BootSignature.jar /recovery new-boot.img $KEYS_PATH/verity.pk8 $KEYS_PATH/verity.x509.pem $IMAGES_PATH/recovery-signed.img

rm -Rf "$RECOVERYFILES_DIR"
rm -Rf "$RECOVERYRAMDISK_DIR"
