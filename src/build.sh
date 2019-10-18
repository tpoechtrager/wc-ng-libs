#!/usr/bin/env bash

set -e

pushd "${0%/*}" &>/dev/null

function build()
{
  if [ "$TARGET" == "osx" ]; then
    ./common/build_osx_fat.sh $1
  else
    ./$1/build.sh
  fi
}

for target in $TARGET; do
  export TARGET=$target
  build dlfcn-win32
  build openssl
  build curl
  #build geoip
  #build mpdclient
  #build pcre
  #build portaudio
  build sensors
  #build ffmpeg
  #build sdl-1.2
  build sdl-2.0
done
