#!/bin/bash

echo
echo "Please enable adb debugging (enable developer mode by clicking 5 times on"
echo "Settings->About Phone->Build number, and then click"
echo "Developer options->enable USB Debugging.)"
echo -n "[Hit Enter to continue...]"
read junk

if [ -z "$(adb devices | grep "device$")" ]
then
  echo
  echo "You have to disconnect and reconnect USB and authorize the"
  echo "debugging connection.."
  echo -n "[Hit Enter to continue...]"
  read junk
fi

cd packages

for i in *.apk
do
  adb install $i
done

adb shell "mkdir /sdcard/MyAppList"
adb push "${MYAPPLIST:-myapplist*xml}" /sdcard/MyAppList/

echo "Disabling captive portal detection"
adb shell "settings put global captive_portal_mode 0"
adb shell "settings put global captive_portal_detection_enabled 0"

echo
echo "Don't forget to disable debugging!"
