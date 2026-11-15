#!/bin/bash
# iOS dependency build (idempotent, skips what is already present)
set -e
IOS_MIN=${IOS_MIN:-17.0}
CM="cmake -G Xcode -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET=$IOS_MIN -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO"

if [ ! -f prefix/lib/libSDL2.a ]; then
  echo "== SDL2"
  git clone --depth 1 -b SDL2 https://github.com/libsdl-org/SDL.git sdl
  $CM -S sdl -B sdl-build -DCMAKE_INSTALL_PREFIX=$PWD/prefix -DSDL_SHARED=OFF -DSDL_STATIC=ON -DSDL_TEST=OFF -DSDL_TESTS=OFF
  cmake --build sdl-build --config Release -- -sdk iphoneos
  cmake --install sdl-build --config Release
fi

if [ ! -f gl4es/lib/Release/libGL.dylib ]; then
  echo "== GL4ES"
  git clone --depth 1 https://github.com/ptitSeb/gl4es.git gl4es
  sed -i '' 's|#ifdef __GNUC__|#if defined(__GNUC__) \&\& !defined(__APPLE__)|' gl4es/src/gl/attributes.h
  $CM -S gl4es -B gl4es-build -DCMAKE_BUILD_TYPE=Release
  cmake --build gl4es-build --config Release -- -sdk iphoneos
fi

if [ ! -f prefix/lib/libSDL2_image.a ]; then
  echo "== SDL2_image"
  git clone --depth 1 -b SDL2 https://github.com/libsdl-org/SDL_image.git sdl_image
  $CM -S sdl_image -B simg-build -DCMAKE_INSTALL_PREFIX=$PWD/prefix -DCMAKE_PREFIX_PATH=$PWD/prefix \
    -DSDL2_INCLUDE_DIR=$PWD/prefix/include/SDL2 -DSDL2_LIBRARY=$PWD/prefix/lib/libSDL2.a \
    -DBUILD_SHARED_LIBS=OFF -DSDL2IMAGE_VENDORED=ON -DSDL2IMAGE_TIF=OFF -DSDL2IMAGE_WEBP=OFF -DSDL2IMAGE_AVIF=OFF -DSDL2IMAGE_JXL=OFF
  cmake --build simg-build --config Release -- -sdk iphoneos || true
  cmake --install simg-build --config Release
fi

if [ ! -f prefix/lib/libogg.a ]; then
  echo "== libogg"
  git clone --depth 1 https://github.com/xiph/ogg.git ogg
  $CM -S ogg -B ogg-build -DCMAKE_INSTALL_PREFIX=$PWD/prefix -DBUILD_SHARED_LIBS=OFF -DINSTALL_DOCS=OFF
  cmake --build ogg-build --config Release -- -sdk iphoneos
  cmake --install ogg-build --config Release
fi

if [ ! -f prefix/lib/libvorbisfile.a ]; then
  echo "== libvorbis"
  git clone --depth 1 https://github.com/xiph/vorbis.git vorbis
  $CM -S vorbis -B vorbis-build -DCMAKE_INSTALL_PREFIX=$PWD/prefix -DCMAKE_PREFIX_PATH=$PWD/prefix \
    -DOGG_INCLUDE_DIR=$PWD/prefix/include -DOGG_LIBRARY=$PWD/prefix/lib/libogg.a -DBUILD_SHARED_LIBS=OFF
  cmake --build vorbis-build --config Release -- -sdk iphoneos
  cmake --install vorbis-build --config Release
fi

if [ ! -f prefix/lib/libopenal.a ]; then
  echo "== OpenAL-Soft"
  git clone --depth 1 https://github.com/kcat/openal-soft.git openal-soft
  $CM -S openal-soft -B oal-build -DCMAKE_INSTALL_PREFIX=$PWD/prefix -DLIBTYPE=STATIC -DALSOFT_EXAMPLES=OFF -DALSOFT_TESTS=OFF -DALSOFT_UTILS=OFF
  cmake --build oal-build --config Release -- -sdk iphoneos
  cmake --install oal-build --config Release
fi

echo "deps ready"
ls -lh prefix/lib/*.a gl4es/lib/Release/libGL.dylib 2>/dev/null
