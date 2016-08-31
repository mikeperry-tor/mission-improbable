#!/bin/bash

echo
echo "Please enable adb debugging (enable developer mode by clicking 5 times on"
echo "Settings->About Phone->Build number, and then click"
echo "Developer options->enable USB Debugging.)"
read junk

cd packages

for i in *.apk
do
  adb install $i
done

adb shell "mkdir /sdcard/MyAppList"
adb push myapplist*xml /sdcard/MyAppList/

echo "Disabling captive portal detection"
adb shell "settings put global captive_portal_detection_enabled 0"

echo
echo "Don't forget to disable debugging!"
