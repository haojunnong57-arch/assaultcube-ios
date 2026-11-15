#!/bin/bash
# Bundle AC.app and create unsigned AssaultCube-iOS.ipa
set -e
AC=upstream
APP=Payload/AssaultCube.app

rm -rf Payload AssaultCube-iOS.ipa
mkdir -p "$APP"

cp AC "$APP/AC"
cp ios/Info.plist "$APP/Info.plist"

for d in packages config mods demos bot; do
  echo "[ASSETS] $d" >> build.log
  ditto "$AC/$d" "$APP/$d"
  du -sh "$APP/$d" >> build.log
done

echo "[ZIP] AssaultCube-iOS.ipa" >> build.log
zip -qry AssaultCube-iOS.ipa Payload
ls -lh AssaultCube-iOS.ipa | tee -a build.log
