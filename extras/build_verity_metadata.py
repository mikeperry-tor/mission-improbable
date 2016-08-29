#! /usr/bin/env python

import os
import sys
import struct
import tempfile
import commands

VERSION = 0
MAGIC_NUMBER = 0xb001b001
BLOCK_SIZE = 4096
METADATA_SIZE = BLOCK_SIZE * 8

def run(cmd):
    status, output = commands.getstatusoutput(cmd)
    print output
    if status:
        exit(-1)

def get_verity_metadata_size(data_size):
    return METADATA_SIZE

def build_metadata_block(verity_table, signature):
    table_len = len(verity_table)
    block = struct.pack("II256sI", MAGIC_NUMBER, VERSION, signature, table_len)
    block += verity_table
    block = block.ljust(METADATA_SIZE, '\x00')
    return block

def sign_verity_table(table, signer_path, key_path):
    with tempfile.NamedTemporaryFile(suffix='.table') as table_file:
        with tempfile.NamedTemporaryFile(suffix='.sig') as signature_file:
            table_file.write(table)
            table_file.flush()
            cmd = " ".join((signer_path, table_file.name, key_path, signature_file.name))
            print cmd
            run(cmd)
            return signature_file.read()

def build_verity_table(block_device, data_blocks, root_hash, salt):
    table = "1 %s %s %s %s %s %s sha256 %s %s"
    table %= (  block_device,
                block_device,
                BLOCK_SIZE,
                BLOCK_SIZE,
                data_blocks,
                data_blocks + (METADATA_SIZE / BLOCK_SIZE),
                root_hash,
                salt)
    return table

def build_verity_metadata(data_blocks, metadata_image, root_hash,
                            salt, block_device, signer_path, signing_key):
    # build the verity table
    verity_table = build_verity_table(block_device, data_blocks, root_hash, salt)
    # build the verity table signature
    signature = sign_verity_table(verity_table, signer_path, signing_key)
    # build the metadata block
    metadata_block = build_metadata_block(verity_table, signature)
    # write it to the outfile
    with open(metadata_image, "wb") as f:
        f.write(metadata_block)

if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "-s":
        print get_verity_metadata_size(int(sys.argv[2]))
    elif len(sys.argv) == 8:
        data_image_blocks = int(sys.argv[1]) / 4096
        metadata_image = sys.argv[2]
        root_hash = sys.argv[3]
        salt = sys.argv[4]
        block_device = sys.argv[5]
        signer_path = sys.argv[6]
        signing_key = sys.argv[7]
        build_verity_metadata(data_image_blocks, metadata_image, root_hash,
                                salt, block_device, signer_path, signing_key)
    else:
        exit(-1)
