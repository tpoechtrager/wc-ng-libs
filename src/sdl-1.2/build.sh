#!/usr/bin/env bash

if [[ "$0" == *sdl-2.0* ]]; then
  PACKAGE="SDL2"
else
  PACKAGE="SDL"
fi

./zlib-ng/build.sh

. ${0%/*}/../common/common.inc.sh

# SDL_mixer deps
download "libogg" "http://downloads.xiph.org/releases/ogg/libogg-1.3.4.tar.xz" \
  "" "sha256" "c163bc12bc300c401b6aa35907ac682671ea376f13ae0969a220f7ddf71893fe"

download "libvorbis" "http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.xz" \
  "" "sha256" "b33cc4934322bcbf6efcbacf49e3ca01aadbea4114ec9589d1b1e9d20f72954b"

# SDL_image deps
download "libjpeg" "http://www.ijg.org/files/jpegsrc.v9c.tar.gz" \
  "" "sha256" "650250979303a649e21f87b5ccd02672af1ea6954b911342ea491f351ceb7122"

download "libpng" "ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16/libpng-1.6.37.tar.xz" \
  "" "sha256" "505e70834d35383537b6491e7ae8641f1a4bed1876dbfe361201fc80868d88ca"

# SDL
if [ $PACKAGE == "SDL2" ]; then
  download "sdl2" "https://www.libsdl.org/release/SDL2-2.0.12.tar.gz" \
    "" "sha256" "349268f695c02efbc9b9148a70b85e58cefbbf704abd3e91be654db7f1e2c863"

  download "sdl2_image" "https://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.5.tar.gz" \
    "" "sha256" "bdd5f6e026682f7d7e1be0b6051b209da2f402a2dd8bd1c4bd9c25ad263108d0"

  download "sdl2_mixer" "https://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-2.0.4.tar.gz" \
    "" "sha256" "b4cf5a382c061cd75081cf246c2aa2f9df8db04bdda8dcdc6b6cca55bede2419"

  download "sdl2_net" "https://www.libsdl.org/projects/SDL_net/release/SDL2_net-2.0.1.tar.gz" \
    "" "sha256" "15ce8a7e5a23dafe8177c8df6e6c79b6749a03fff1e8196742d3571657609d21"
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
patch -p0 < $PATCH_DIR/ogg-darwin.patch
test $ISOSX -eq 1 && patch -p0 < $PATCH_DIR/ogg-osx-cflags.patch
./configure --prefix=$TARGET_DIR $CONFIGURE_FLAGS --with-pic
$MAKE -j $JOBS install
popd

# vorbis
echo_action "building libvorbis"
pushd libvorbis*
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
pushd $(echo SDL*-* | tr ' ' '\n' | grep -v image | grep -v mixer|head -n1)
CONFIGURE_FLAGS_OLD=$CONFIGURE_FLAGS
if [ $PACKAGE == "SDL" ]; then
  patch -p1 < $PATCH_DIR/sdl-xdata32.patch
fi
if [ $ISOSX -eq 1 -o $ISARM -eq 1 ]; then
  CONFIGURE_FLAGS+=" --with-x=no"
fi
./autogen.sh &>/dev/null
if [ $ISFBSD -eq 1 -a "$PLATFORM" != "$NATIVE_PLATFORM" ]; then
  X11PATH="$(dirname $(echo "#include <stdlib.h>" | $CC -E - | \
             grep "stdlib.h" | head -n1 | awk {'print $3'}   | \
             sed "s/\"//g" -))/../local/lib"
  sed -i'' -e 's|host_lib_path=""|host_lib_path="'$X11PATH'"|g' configure
fi
if [ -n "$HUAWEI_TOOL" ]; then
  rm src/dynapi/SDL_dynapi.h
  echo "#define SDL_DYNAMIC_API 0" > src/dynapi/SDL_dynapi.h
  ./configure \
    --prefix=$TARGET_DIR \
     $CONFIGURE_FLAGS \
    --disable-atomic \
    --disable-video \
    --disable-audio \
    --disable-render \
    --disable-events \
    --disable-joystick \
    --disable-haptic \
    --disable-sensor \
    --disable-power \
    --disable-filesystem \
    --disable-threads \
    --disable-timers \
    --disable-file \
    --disable-loadso \
    --disable-cpuinfo \
    --disable-assembly \
    --enable-assertions=release \
    --disable-render-d3d \
    --disable-video-vulkan \
    --disable-video-dummy \
    --enable-libudev=no \
    --enable-dbus=no \
    --enable-input-tslib=no \
    --with-x=no \
    --with-pic
else
if [ $ISLINUX -eq 1 ]; then
  export PULSEAUDIO_CFLAGS="-D_REENTRANT "
  export PULSEAUDIO_LIBS="-lpulse-simple -lpulse -pthread "
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
fi
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
  make -j $JOBS libSDL2_image.la
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

########### SDL_net ###########

# SDL_net

echo_action "building SDL_net"
pushd SDL*net*
./configure \
  --prefix=$TARGET_DIR $CONFIGURE_FLAGS
sed -i'' -e "s/am__EXEEXT_1/#am__EXEEXT_1/g" Makefile
make -j $JOBS install
popd

finish_libs
