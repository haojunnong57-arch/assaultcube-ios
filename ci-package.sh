#!/bin/bash
# Bundle AC.app and create unsigned AssaultCube-iOS.ipa
set -e
AC=upstream
APP=Payload/AssaultCube.app

rm -rf Payload AssaultCube-iOS.ipa
mkdir -p "$APP/Frameworks"

cp AC "$APP/AC"
cp ios/Info.plist "$APP/Info.plist"
cp gl4es/lib/Release/libGL.dylib "$APP/Frameworks/"

for d in packages config mods demos bot; do
  echo "[ASSETS] $d"
  ditto "$AC/$d" "$APP/$d"
  du -sh "$APP/$d" | tee -a build.log
  echo "$d" >> build.log
  du -sh "$APP/$d" >> build.log
done

echo "[ZIP] AssaultCube-iOS.ipa" >> build.log
zip -qry AssaultCube-iOS.ipa Payload
ls -lh AssaultCube-iOS.ipa | tee -a build.log
