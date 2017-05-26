#!/bin/bash
# vim:ts=2 sw=2 sts=2 expandtab:

set -e

usage() {
  echo "Usage: $0 [-h] -c <copperhead_factory_dir> [-g <gapps.zip> -r <twrp.img>] [--no-tor] "
  echo
  echo "Required arguments:"
  echo "  -c|--copperhead          Path to unpacked factory image for your device."
  echo
  echo "Optional arguments"
  echo "  -a|--myapplist           Path to MyAppList XML file.  Defaults to the one in the repository."
  echo "  -g|--gapps <gapps.zip>   Path to GApps.zip you wish to use."
  echo "  -h|--help                This usage output."
  echo "  -r|--recovery <twrp.img> Path to TWRP recovery image."
  echo "  -T|--no-tor              Don't install orbot or orwall."
  exit 1
}

# Use GNU getopt to capture arguments as it allows us to have long options
# which the bash builtin getopts doesn't support.  We also still support the
# old # positional arguments for now, but don't advertise them in the usage().
TEMP=$(getopt -o 'ha:c:g:r:T::' --long 'help,myapplist,copperhead:,gapps:,recovery:,no-tor::' -- "$@")
[ $? -ne 0 ] && usage
eval set -- "$TEMP"; unset TEMP
# Set defaults
NO_TOR=0
# Parse the args
while true; do
  case "$1" in
    '-a'|'--myapplist')
      if [ -r "$2" ]; then
        MYAPPLIST="$2"
        shift 2
        continue
      else
        echo "File not found: '$2'"
        exit 1
      fi
      ;;
    '-c'|'--copperhead')
      COPPERHEAD_DIR=$2
      shift 2;
      continue
      ;;
    '-g'|'--gapps')
      GAPPS_ZIP=$2
      shift 2
      continue
      ;;
    '-r'|'--recovery')
      TWRP_IMG=$2
      shift 2
      continue
      ;;
    '-T'|'--no-tor')
      NO_TOR=1
      shift
      continue
      ;;
    '-h'|'--help')
      usage
      ;;
    '-*')
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    '--')
      shift
      break
      ;;
    *)
      POSITIONAL="$POSITIONAL $1"
      shift
      continue
      ;;
  esac
done

set +e
# Backwards compatibility for positional arguments
[ -z $COPPERHEAD_DIR ] && [ -n $1 ] && COPPERHEAD_DIR=$1 && shift
[ -z $GAPPS_ZIP ] && [ -n $1 ] && GAPPS_ZIP=$1 && shift
[ -z $TWRP_IMG ] && [ -n $1 ] && TWRP_IMG=$1 && shift
set -e

export MYAPPLIST
export COPPERHEAD_DIR
export GAPPS_ZIP
export TWRP_IMG
export NO_TOR

# Bail out if no Copperhead directory was provided
[ -z ${COPPERHEAD_DIR} ] && usage

# Enforce none or both of GAPPS_ZIP and TWRP_IMG being supplied
if [[ -n $GAPPS_ZIP && -z $TWRP_IMG ]] || [[ -z $GAPPS_ZIP && -n $TWRP_IMG ]]; then
  usage
fi

SUPERBOOT_DIR=$PWD/helper-repos/super-bootimg
SIMG2IMG_DIR=$PWD/helper-repos/android-simg2img

./clone-helper-repos.sh $SUPERBOOT_DIR $SIMG2IMG_DIR
./fetch-apks.sh

if [ ! -f ./keys/verity_key.pub ];
then
  cd keys
  ./make_keys.sh $SIMG2IMG_DIR
  cd -
fi

./install-su.sh $COPPERHEAD_DIR $SUPERBOOT_DIR

if [ ! -f "$TWRP_IMG" -o ! -f "$GAPPS_ZIP" ];
then
  ./apply-gapps-delta.sh $COPPERHEAD_DIR $SIMG2IMG_DIR
else
  # XXX: Ok to run after install-su.sh?
  ./install-copperhead.sh $COPPERHEAD_DIR
  ./install-gapps.sh $TWRP_IMG $GAPPS_ZIP
fi

./re-sign.sh $COPPERHEAD_DIR $SIMG2IMG_DIR $SUPERBOOT_DIR

./flash-signed.sh

./install-packages.sh

echo
echo "All done! Yay!"
