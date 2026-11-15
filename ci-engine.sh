#!/bin/bash
# Compile AssaultCube engine (acmobile) for iOS arm64 and link the app binary
set -e
IOS_MIN=${IOS_MIN:-17.0}
AC=upstream

if [ ! -d "$AC" ]; then
  git clone --depth 1 -b acmobile https://github.com/assaultcube/AC.git "$AC"
fi
if [ ! -d gl4es ]; then
  git clone --depth 1 https://github.com/ptitSeb/gl4es.git gl4es
fi

SDK=$(xcrun --sdk iphoneos --show-sdk-path)
CC="xcrun --sdk iphoneos clang   -arch arm64 -isysroot $SDK -mios-version-min=$IOS_MIN"
CXX="xcrun --sdk iphoneos clang++ -arch arm64 -isysroot $SDK -mios-version-min=$IOS_MIN"
INC="-Istubs -Igl4es/include -Iprefix/include/SDL2 -Iprefix/include -I$AC/source/src -I$AC/source/include -I$AC/source/enet/include"
CFLAGS="-D__ANDROID__ -O2"
CXXFLAGS="-D__ANDROID__ -std=c++11 -fno-rtti -fno-exceptions -fsigned-char -fstack-protector -O2"

# iOS data-path patches
sed -i.bak 's|"/storage/emulated/0/Android/data/net.cubers.assaultcube/files/";|getenv("AC_BASE_DIR");|' "$AC/source/src/stream.cpp"
sed -i.bak 's|#define DEFAULTPROFILEPATH "profile"|#define DEFAULTPROFILEPATH (getenv("AC_HOME_DIR")?getenv("AC_HOME_DIR"):"profile")|' "$AC/source/src/main.cpp"
# SDL >= 2.0.18 no longer ships KMOD_LMETA/KMOD_RMETA; use the GUI (Cmd) equivalents
sed -i.bak 's|#define MOD_KEYS_CTRL (KMOD_LMETA|KMOD_RMETA)|#define MOD_KEYS_CTRL (KMOD_LGUI|KMOD_RGUI)|' "$AC/source/src/platform.h"

grep -n "AC_BASE_DIR\|AC_HOME_DIR\|KMOD_LGUI" "$AC/source/src/stream.cpp" "$AC/source/src/main.cpp" "$AC/source/src/platform.h" >> build.log 2>&1 || true

mkdir -p objs

SRCS="crypto audiomanager autodownload client clientgame clients2c command console docs editing entities http log main menus touch/touch oggstream openal packetqueue physics protocol rendercubes rendergl renderhud rendermodel renderparticles rendertext rndmap scoreboard serverms server serverbrowser shadow soundlocation soundscheduler stream texture tools water weapon wizard world worldio worldlight worldocull worldrender zip bot/bot bot/botmanager bot/bot_ai bot/bot_util bot/bot_waypoint bot/ac_bot bot/ac_bot_ai"

pids=""
for f in $SRCS; do
  o="objs/$(echo "$f" | tr '/' '_').o"
  ( echo "[CXX] $f" >> build.log; $CXX $CXXFLAGS $INC -c "$AC/source/src/$f.cpp" -o "$o" >> build.log 2>&1 ) &
  pids="$pids $!"
  if [ $(echo $pids | wc -w) -ge 4 ]; then
    for p in $pids; do wait $p || exit 1; done
    pids=""
  fi
done
for p in $pids; do wait $p || exit 1; done

CSRCS="list callbacks compress host packet peer protocol unix win32"
for f in $CSRCS; do
  echo "[CC] enet/$f" >> build.log
  $CC $CFLAGS $INC -c "$AC/source/enet/$f.c" -o "objs/enet_$f.o" >> build.log 2>&1 || exit 1
done

echo "[OBJCXX] ios/main.m" >> build.log
$CXX -x objective-c++ -fobjc-arc -arch arm64 -isysroot $SDK -mios-version-min=$IOS_MIN \
  -Iprefix/include/SDL2 -c ios/main.m -o objs/ios_main.o >> build.log 2>&1 || exit 1

echo "[LINK] AC" >> build.log
$CXX objs/*.o -o AC \
  -Lprefix/lib -lSDL2 -lSDL2_image -lopenal -logg -lvorbis -lvorbisfile \
  -Lgl4es/lib/Release -lGL -Wl,-rpath,@executable_path/Frameworks \
  -lz -lsqlite3 -liconv \
  -framework UIKit -framework OpenGLES -framework QuartzCore -framework CoreAudio \
  -framework AudioToolbox -framework AVFoundation -framework CoreMotion -framework GameController \
  -framework CoreHaptics -framework Metal -framework CoreGraphics -framework CoreFoundation \
  -framework Foundation -framework ImageIO -framework Security -framework CoreBluetooth \
  -framework CoreServices -framework CoreMedia -framework CoreVideo -framework CFNetwork \
  >> build.log 2>&1 || { tail -40 build.log; exit 1; }

ls -lh AC >> build.log
file AC >> build.log
