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

def WriteRadio(info, radio_img, dest_dir):
  outfile = open(dest_dir+"/"+"radio.img", "wb")
  outfile.write(radio_img)
  outfile.close()

def ParseBootloaderHeader(bootloader):
  header_fmt = "<8sIII"
  header_size = struct.calcsize(header_fmt)
  magic, num_images, start_offset, bootloader_size = struct.unpack(
      header_fmt, bootloader[:header_size])
  assert magic == "BOOTLDR!", "bootloader.img bad magic value"

  img_info_fmt = "<64sI"
  img_info_size = struct.calcsize(img_info_fmt)

  imgs = [struct.unpack(img_info_fmt,
                        bootloader[header_size+i*img_info_size:
                                   header_size+(i+1)*img_info_size])
          for i in range(num_images)]

  p = start_offset
  img_dict = {}
  for name, size in imgs:
    img_dict[trunc_to_null(name)] = p, size
    p += size
  assert p - start_offset == bootloader_size, "bootloader.img corrupted"

  return img_dict


# bullhead's bootloader.img contains 11 separate images.
# Each goes to its own partition:
#    sbl1, tz, rpm, aboot, sdi, imgdata, pmic, hyp, sec, keymaster, cmnlib
#
# bullhead also has 8 backup partitions:
#    sbl1, tz, rpm, aboot, pmic, hyp, keymaster, cmnlib
#
release_backup_partitions = "sbl1 tz rpm aboot pmic hyp keymaster cmnlib"
debug_backup_partitions = "sbl1 tz rpm aboot pmic hyp keymaster cmnlib"
release_nobackup_partitions = "sdi imgdata sec"
debug_nobackup_partitions = "sdi imgdata sec"


def WriteBootloader(info, bootloader, dest_dir):
  #info.script.Print("Writing bootloader...")

  img_dict = ParseBootloaderHeader(bootloader)

  outfile = open(dest_dir+"/"+"bootloader-flag.txt", "wb")
  outfile.write("updating-bootloader" + "\0" * 13)
  outfile.close()

  outfile = open(dest_dir+"/"+"bootloader-flag-clear.txt", "wb")
  outfile.write("\0" * 32)
  outfile.close()

  to_bkp_flash = release_backup_partitions.split()
  to_flash = release_nobackup_partitions.split()

  for i in to_bkp_flash:
    outfile = open(dest_dir+"/"+"bootloader.%s.img" % (i,), "wb")
    outfile.write(bootloader[img_dict[i][0]:
                                  img_dict[i][0]+img_dict[i][1]])
    outfile.close()
  
  for i in to_flash:
    outfile = open(dest_dir+"/"+"bootloader.%s.img" % (i,), "wb")
    outfile.write(bootloader[img_dict[i][0]:
                                  img_dict[i][0]+img_dict[i][1]])
    outfile.close()


def trunc_to_null(s):
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
