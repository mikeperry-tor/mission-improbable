#!/usr/bin/env python
#
# Copyright (C) 2015 The Android Open-Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import common
import struct
import sys

# The target does not support OTA-flashing
# the partition table, so blacklist it.
DEFAULT_BOOTLOADER_OTA_BLACKLIST = ['partition']


class BadMagicError(Exception):
  __str__ = "bad magic value"

#
# Huawei Bootloader packed image format
#
# typedef struct meta_header {
#  u32   magic;             /* 0xce1ad63c */
#  u16   major_version;     /* (0x1)-reject images with higher major versions */
#  u16   minor_version;     /* (0x0)-allow images with higer minor versions */
#  char  img_version[64];   /* Top level version for images in this meta */
#  u16   meta_hdr_sz;       /* size of this header */
#  u16   img_hdr_sz;        /* size of img_header_entry list */
# } meta_header_t;

# typedef struct img_header_entry {
#  char   ptn_name[MAX_GPT_NAME_SIZE];
#  u32    start_offset;
#  u32    size;
# } img_header_entry_t


MAGIC = 0xce1ad63c


class HuaweiBootImage(object):

  def __init__(self, data, name=None):
    self.name = name
    self.unpacked_images = None
    self._unpack(data)

  def _unpack(self, data):
    """Unpack the data blob as a Huawei boot image and return the list
    of contained image objects"""
    num_imgs_fmt = struct.Struct("<IHH64sHH")
    header = data[0:num_imgs_fmt.size]
    info = {}
    (info["magic"], info["major_version"],
     info["minor_version"], info["img_version"],
     info["meta_hdr_size"], info["img_hdr_size"]) = num_imgs_fmt.unpack(header)

    img_info_format = "<72sLL"
    img_info_size = struct.calcsize(img_info_format)
    num = info["img_hdr_size"] / img_info_size
    size = num_imgs_fmt.size
    imgs = [
         struct.unpack(
             img_info_format,
             data[size + i * img_info_size:size + (i + 1) * img_info_size])
         for i in range(num)
    ]

    if info["magic"] != MAGIC:
      raise BadMagicError

    img_objs = {}
    for name, start, end in imgs:
      if TruncToNull(name):
        img = common.File(TruncToNull(name), data[start:start + end])
        img_objs[img.name] = img

    self.unpacked_images = img_objs

  def GetUnpackedImage(self, name):
    return self.unpacked_images.get(name)


def WriteRadio(info, radio_img, dest_dir):
  #info.script.Print("Writing radio...")

  try:
    huawei_boot_image = HuaweiBootImage(radio_img, "radio")
  except BadMagicError:
    raise ValueError("radio.img bad magic value")

  WriteHuaweiBootPartitionImages(info, huawei_boot_image, dest_dir)

def WriteHuaweiBootPartitionImages(info, huawei_boot_image, dest_dir,
                                   blacklist=None):
  if blacklist is None:
    blacklist = []
  WriteGroupedImages(info, huawei_boot_image.name,
                     huawei_boot_image.unpacked_images.values(),
                     dest_dir,
                     blacklist)

def WriteGroupedImages(info, group_name, images, dest_dir, blacklist=None):
  """Write a group of partition images to the OTA package,
  and add the corresponding flash instructions to the recovery
  script.  Skip any images that do not have a corresponding
  entry in recovery.fstab."""
  if blacklist is None:
    blacklist = []
  for i in images:
    if i.name not in blacklist:
      WritePartitionImage(info, i, dest_dir, group_name)

def WritePartitionImage(info, image, dest_dir, group_name=None):
  filename = "%s.img" % (image.name)
  if group_name:
    filename = "%s.%s" % (group_name, filename)

  print "Writing radio image to "+dest_dir+"/"+filename
  outfile = open(dest_dir+"/"+filename, "wb")
  outfile.write(image.data)

def WriteBootloader(info, bootloader, dest_dir, blacklist=None):
  if blacklist is None:
    blacklist = DEFAULT_BOOTLOADER_OTA_BLACKLIST
  #info.script.Print("Writing bootloader...")
  try:
    huawei_boot_image = HuaweiBootImage(bootloader, "bootloader")
  except BadMagicError:
    raise ValueError("bootloader.img bad magic value")

  outfile = open(dest_dir+"/"+"bootloader-flag.txt", "wb")
  outfile.write("updating-bootloader" + "\0" * 13)
  outfile.close()

  outfile = open(dest_dir+"/"+"bootloader-flag-clear.txt", "wb")
  outfile.write("\0" * 32)
  outfile.close()

  # OTA does not support partition changes, so
  # do not bundle the partition image in the OTA package.
  WriteHuaweiBootPartitionImages(info, huawei_boot_image, dest_dir, blacklist)

def TruncToNull(s):
  if '\0' in s:
    return s[:s.index('\0')]
  else:
    return s

# ====================================================

def usage():
  print "Usage: "+__file__+" <factory_radio.img> <factory_bootloader.img> <ota_dir>"
  sys.exit(0)

def main(argv):
  if len(argv) != 4:
    usage()

  print "Reading radio "+argv[1]
  radio = open(argv[1], "rb")
  WriteRadio({}, radio.read(), argv[3])
  radio.close()

  print "Reading BootLoader "+argv[2]
  bootloader = open(argv[2], "rb")
  WriteBootloader({}, bootloader.read(), argv[3])

if __name__ == '__main__':
  main(sys.argv)
