#!/usr/bin/env bash

PACKAGE="SDL2"

./zlib/build.sh

. ${0%/*}/../common/common.inc.sh

# SDL_mixer deps
download "libogg" "https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-1.3.5.tar.xz" \
  "" "sha256" "c4d91be36fc8e54deae7575241e03f4211eb102afb3fc0775fbbc1b740016705"

download "libvorbis" "https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-1.3.7.tar.xz" \
  "" "sha256" "b33cc4934322bcbf6efcbacf49e3ca01aadbea4114ec9589d1b1e9d20f72954b"

# SDL_image deps
download "libjpeg" "https://www.ijg.org/files/jpegsrc.v9f.tar.gz" \
  "" "sha256" "04705c110cb2469caa79fb71fba3d7bf834914706e9641a4589485c1f832565b"

download "libpng" "https://ftp2.osuosl.org/pub/blfs/conglomeration/libpng/libpng-1.6.47.tar.xz" \
  "" "sha256" "b213cb381fbb1175327bd708a77aab708a05adde7b471bc267bd15ac99893631"

# SDL
download "sdl2" "https://www.libsdl.org/release/SDL2-2.30.6.tar.gz" \
  "" "sha256" "c6ef64ca18a19d13df6eb22df9aff19fb0db65610a74cc81dae33a82235cacd4"

download "sdl2_image" "https://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.8.2.tar.gz" \
  "" "sha256" "8f486bbfbcf8464dd58c9e5d93394ab0255ce68b51c5a966a918244820a76ddc"

download "sdl2_mixer" "https://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-2.8.0.tar.gz" \
  "" "sha256" "1cfb34c87b26dbdbc7afd68c4f545c0116ab5f90bbfecc5aebe2a9cb4bb31549"

extract_archives

########### SDL_mixer deps ###########

# ogg
echo_action "building libogg"
pushd libogg*
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
if [ $ISLINUX -eq 1 -a $ISARM -eq 0 ]; then
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
if [ $ISOSX -eq 1 ]; then
export LDFLAGS+=" -Wl,-framework,Foundation"
fi
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
  make -j $JOBS libSDL_image.lacd
fi
make -j $JOBS install
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
make -j $JOBS install
popd

finish_libs
