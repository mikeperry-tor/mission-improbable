#!/bin/bash
dep=true
command -v java >/dev/null 2>&1 || { echo "Java is not installed!" >&2; exit 1; dep=false; }
command -v adb >/dev/null 2>&1 || { echo "ADB is not installed." >&2; exit 1; dep=false; }
command -v python >/dev/null 2>&1 || { echo "Python is not installed." >&2; exit 1; dep=false; }
if [ "$dep" = "false" ]; then
while true; do
    echo "One or more packages is missing!"
    read -p "Would you like to install now? (y/n)" yn
    case $yn in
        [Yy]* ) echo "This will require sudo..."; sudo apt-get install -qq default-jre python adb;;
        [Nn]* ) echo "Aborting..."; break;;
        * ) echo "Please answer y or n.";;
    esac
done
else
    echo "All packages are installed! Make sure to respond "1" to next prompt!"
    sleep 2
    python extras/tingle/main.py
fi
