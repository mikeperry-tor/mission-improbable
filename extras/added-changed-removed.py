#!/usr/bin/env python
#
# Output two files, one containing all added/changed files between two
# directories, and the other containing all removed files, one
# filename per line.
#
# Author(s):
#   - isis agora lovecruft <isis@torproject.org> 0xa3adb67a2cdb8b35
# License: WTFPL/CC0-1.0

from __future__ import print_function

import hashlib
import os
import sys

def recursive_listdir(d):
    full_list = []

    cur = os.getcwd()
    os.chdir(d)

    for root, dirs, files in os.walk("."):
        for dr in dirs:
            full_list.append(os.path.normpath(os.path.join(root, dr)))
        for fl in files:
            full_list.append(os.path.normpath(os.path.join(root, fl)))

    os.chdir(cur)
    return full_list

# aka changed
def changed_in_b(a, b):
    both = set(recursive_listdir(a)).intersection(set(recursive_listdir(b)))
    changed = []

    fha, fhb = None, None

    for filename in both:
        fna = os.path.normpath(os.sep.join([a, filename]))
        fnb = os.path.normpath(os.sep.join([b, filename]))

        if os.path.isdir(fna) and os.path.isdir(fnb):
          continue

        if os.path.islink(fna):
          a_data = os.readlink(fna)
        else:
          fha = open(fna)
          a_data = fha.read()

        if os.path.islink(fnb):
          b_data = os.readlink(fnb)
        else:
          fhb = open(fnb)
          b_data = fhb.read()

        fhh = hashlib.sha256(a_data).hexdigest()
        fhg = hashlib.sha256(b_data).hexdigest()

        if fhh != fhg:
            changed.append(fnb)

    for fh in (fha, fhb):
        try:
            if fh:
                fh.close()
        except Exception as err:
            print("Exception while trying to close file: %s" % err)

    return changed
            
# aka removed
def in_a_not_b(a, b):
    a_contents = recursive_listdir(a)
    b_contents = recursive_listdir(b)

    diff = list(set(a_contents).difference(set(b_contents)))
    files = []

    for fn in diff:
        files.append(os.path.normpath(os.sep.join([b, fn])))

    return files

# aka added
def in_b_not_a(a, b):
    a_contents = recursive_listdir(a)
    b_contents = recursive_listdir(b)

    diff = list(set(b_contents).difference(set(a_contents)))
    files = []

    for fn in diff:
        files.append(os.path.normpath(os.sep.join([b, fn])))

    return files


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
    else:
        dir_a = sys.argv[1]
        dir_b = sys.argv[2]

        added_files = in_b_not_a(dir_a, dir_b)
        removed_files = in_a_not_b(dir_a, dir_b)
        changed_files = changed_in_b(dir_a, dir_b)

        added_files.extend(changed_files)

        af = "added-or-changed-files"
        fh = open(af, "w")
        for line in added_files:
            fh.write(line + '\n')

        print("Added/changed files in %s are in %s" % (dir_b, af))

        rf = "removed-files"
        fh = open(rf, "w")
        for line in removed_files:
            fh.write(line + '\n')

        print("Removed files are in %s" % (rf))
