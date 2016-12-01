#!/bin/bash
if [ -f extras/tingle/pycompatlayer.pyc || -f extras/tools/smali.jar || -f extras/tools/baksmali.jar ]; then
  echo "All dependencies found, respond '1' to next prompt!"
  sleep 1
else
  echo "Building dependencies.."
  python -m compileall extras/tingle/libs/pycompatlayer.py
  javac extras/tingle/misc/ApkSig.java
  cd extras/tingle/tools
  git clone https://github.com/JesusFreke/smali.git
  ./smali/gradlew proguard
  mv baksmali/build/libs/baksmali-*-dev-small.jar baksmali.jar
  mv smali/build/libs/smali-*-dev-small.jar smali.jar
  rm -rf smali
fi
python extras/tingle/main.py
