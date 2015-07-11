#!/usr/bin/env bash

if [[ "$0" == *sdl-2.0* ]]; then
  PACKAGE="SDL2"
else
  PACKAGE="SDL"
fi

. ${0%/*}/../common/common.inc.sh

# SDL_mixer deps
download "libogg" "http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.xz" \
  "" "sha256" "3f687ccdd5ac8b52d76328fbbfebc70c459a40ea891dbf3dccb74a210826e79b"

download "libvorbis" "http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.4.tar.xz" \
  "" "sha256" "2f05497d29195dc23ee952a24ee3973a74e6277569c4c2eca0ec5968e541f372"

# SDL_image deps
download "libjpeg" "http://www.ijg.org/files/jpegsrc.v9a.tar.gz" \
  "" "sha256" "3a753ea48d917945dd54a2d97de388aa06ca2eb1066cbfdc6652036349fe05a7"

download "zlib" "http://zlib.net/zlib-1.2.8.tar.gz" \
  "" "sha256" "36658cb768a54c1d4dec43c3116c27ed893e88b02ecfcb44f2166f9c0b7f2a0d"

download "libpng" "ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16/libpng-1.6.17.tar.xz" \
  "" "sha256" "98507b55fbe5cd43c51981f2924e4671fd81fe35d52dc53357e20f2c77fa5dfd"

# SDL
if [ $PACKAGE == "SDL2" ]; then
  download "sdl2" "https://www.libsdl.org/release/SDL2-2.0.3.tar.gz" \
    "" "sha256" "a5a69a6abf80bcce713fa873607735fe712f44276a7f048d60a61bb2f6b3c90c"

  download "sdl2_image" "https://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.0.tar.gz" \
    "" "sha256" "b29815c73b17633baca9f07113e8ac476ae66412dec0d29a5045825c27a47234"

  download "sdl2_mixer" "https://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-2.0.0.tar.gz" \
    "" "sha256" "a8ce0e161793791adeff258ca6214267fdd41b3c073d2581cd5265c8646f725b"
else
  download "sdl" "https://www.libsdl.org/release/SDL-1.2.15.tar.gz" \
    "" "sha256" "d6d316a793e5e348155f0dd93b979798933fb98aa1edebcc108829d6474aad00"

  download "sdl_image" "http://www.libsdl.org/projects/SDL_image/release/SDL_image-1.2.12.tar.gz" \
    "" "sha256" "0b90722984561004de84847744d566809dbb9daf732a9e503b91a1b5a84e5699"

  download "sdl_mixer" "http://www.libsdl.org/projects/SDL_mixer/release/SDL_mixer-1.2.12.tar.gz" \
    "" "sha256" "1644308279a975799049e4826af2cfc787cad2abb11aa14562e402521f86992a"

  if [ $PLATFORM == "Darwin" ]; then
    wrongsdk=0

    if [ $NATIVE_PLATFORM != "Darwin" ]; then
      if [ "$OSXCROSS_TARGET" != "darwin9" ]; then
        wrongsdk=1
      fi
    elif [ "$(xcrun --show-sdk-version)" != "10.5" ]; then
      wrongsdk=1
    fi

    if [ $wrongsdk -eq 1 ]; then
      echo_error "SDL 1.2 must be built with the 10.5 SDK!"
      exit 1
    fi
  fi
fi

extract_archives

########### SDL_mixer deps ###########

# ogg
echo_action "building libogg"
pushd libogg*
patch -p0 < $PATCH_DIR/ogg-configure.patch
test $ISOSX -eq 1 && patch -p0 < $PATCH_DIR/ogg-osx-cflags.patch
./configure --prefix=$TARGET_DIR $CONFIGURE_FLAGS --with-pic
$MAKE -j $JOBS install
popd

# vorbis
echo_action "building libvorbis"
pushd libvorbis*
patch -p0 < $PATCH_DIR/vorbis-configure.patch
test $ISOSX -eq 1 && patch -p0 < $PATCH_DIR/vorbis-osx.patch
./configure --prefix=$TARGET_DIR $CONFIGURE_FLAGS --with-pic
$MAKE -j $JOBS install
popd

########### SDL_image deps ###########

# jpeg
echo_action "building libjpeg"
pushd jpeg*
./configure --prefix=$TARGET_DIR $CONFIGURE_FLAGS --with-pic
$MAKE -j $JOBS install
popd

# zlib
echo_action "building zlib"
pushd zlib*
if [ $ISMINGW -ne 1 ]; then
  ./configure
  $MAKE -j $JOBS CFLAGS="$CFLAGS -fPIC" libz.a
else
  [[ -n "$HOST" ]] && PREFIX="${HOST}-"
  make -f win32/Makefile.gcc PREFIX=$PREFIX CC=$CC CFLAGS="$CFLAGS" libz.a
  unset PREFIX
fi
mkdir -p $TARGET_DIR/lib $TARGET_DIR/include
$INSTALL -p -D libz.a $TARGET_DIR/lib/libz.a
$INSTALL -p -D zlib.h zconf.h $TARGET_DIR/include
popd

# png
echo_action "building libpng"

pushd libpng*
./configure \
  --prefix=$TARGET_DIR $CONFIGURE_FLAGS --with-pic
patch -p0 < $PATCH_DIR/png-warning.patch
$MAKE -j $JOBS install
popd

###########    SDL    ###########
echo_action "building SDL"
pushd SDL*-*
CONFIGURE_FLAGS_OLD=$CONFIGURE_FLAGS
if [ $PACKAGE == "SDL" ]; then
  patch -p1 < $PATCH_DIR/sdl-xdata32.patch
fi
if [ $ISOSX -eq 1 ]; then
  CONFIGURE_FLAGS+=" --with-x=no"
fi
./autogen.sh &>/dev/null
if [ $ISFBSD -eq 1 -a "$PLATFORM" != "$NATIVE_PLATFORM" ]; then
  X11PATH="$(dirname $(echo "#include <stdlib.h>" | $CC -E - | \
             grep "stdlib.h" | head -n1 | awk {'print $3'}   | \
             sed "s/\"//g" -))/../local/lib"
  sed -i'' -e 's|host_lib_path=""|host_lib_path="'$X11PATH'"|g' configure
fi
./configure \
  --prefix=$TARGET_DIR $CONFIGURE_FLAGS \
  --enable-video-directfb=no --enable-video-svga=no \
  --enable-shared=no --enable-assertions=release \
  --enable-render=no --enable-joystick=no \
  --enable-haptic=no --enable-power=no \
  --disable-alsatest --enable-diskaudio=no \
  --enable-dummyaudio=no --enable-video-dummy=no \
  --enable-libudev=no --enable-dbus=no \
  --enable-input-tslib=no --enable-render-d3d=no \
  --enable-x11-shared --with-pic
CONFIGURE_FLAGS=$CONFIGURE_FLAGS_OLD
$MAKE -j $JOBS install
if [ $PACKAGE == "SDL2" ]; then
  sed -i'' -e "s/-XCClinker//g" $TARGET_DIR/bin/sdl2-config
  sed -i'' -e "s/-XCClinker//g" $TARGET_DIR/lib/pkgconfig/sdl2.pc
fi
popd

########### SDL_image ###########

# SDL_image
echo_action "building SDL_image"
pushd SDL*image*
./configure \
  --prefix=$TARGET_DIR $CONFIGURE_FLAGS \
  --enable-png-shared=no --enable-jpg-shared=no \
  --enable-tif-shared=no --enable-webp-shared=no \
  --enable-webp=no --enable-imageio=no \
  --enable-bmp=no --enable-gif=no \
  --enable-jpg-sharedble-pnm=no \
  --enable-webp=no --enable-tif=no \
  --enable-lbm=no --enable-pcx=no \
  --enable-tga=no --enable-xcf=no \
  --enable-xpm=no --enable-xv=no \
  --disable-sdltest --with-pic
if [ $PACKAGE == "SDL2" ]; then
  sed -i'' -e "s/PROGRAMS = \$(noinst_PROGRAMS)//g" $TARGET_DIR/bin/sdl2-config
  make -j $JOBS
else
  make -j $JOBS libSDL_image.la
fi
if [ -n "$AR" ]; then
  rm -f $TARGET_DIR/lib/lib${PACKAGE}_image.a
  $AR rc $TARGET_DIR/lib/lib${PACKAGE}_image.a *.o
  mkdir -p $TARGET_DIR/include/$PACKAGE
  $INSTALL -p -D SDL*.h $TARGET_DIR/include/$PACKAGE
else
  make -j $JOBS install
fi
popd

########### SDL_mixer ###########

# SDL_mixer
echo_action "building SDL_mixer"
pushd SDL*mixer*
if [ $PACKAGE == "SDL" ]; then
  sed -i'' -e "s/-lvorbisfile  /-lvorbisfile -lvorbis -logg -lm /g" configure
fi
./configure \
  --prefix=$TARGET_DIR $CONFIGURE_FLAGS \
  --enable-music-cmd=no --enable-music-mod=no \
  --enable-music-mod-modplug=no --enable-music-mod-mikmod=no \
  --enable-music-midi=no --enable-music-midi-timidity=no \
  --enable-music-midi-native=no --enable-music-midi-fluidsynth=no \
  --enable-music-flac=no --enable-music-ogg-shared=no \
  --enable-music-mp3=no --enable-music-mp3-smpeg=no \
  --enable-music-mp3-mad-gpl=no --disable-smpegtest \
  --disable-sdltest --with-pic
make -j $JOBS install-lib
if [ -n "$AR" ]; then
  rm -f $TARGET_DIR/lib/lib${PACKAGE}_mixer.a
  $AR rc $TARGET_DIR/lib/lib${PACKAGE}_mixer.a build/*.o
  mkdir -p $TARGET_DIR/include/$PACKAGE
  $INSTALL -p -D SDL*.h $TARGET_DIR/include/$PACKAGE
fi
popd

finish_libs
