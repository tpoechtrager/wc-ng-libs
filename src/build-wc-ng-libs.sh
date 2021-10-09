#!/usr/bin/env bash

set -e

pushd "${0%/*}" &>/dev/null

unset ENABLE_LTO
unset HOSTPREFIX
unset CC CXX
unset USECLANG

rm -rf target build

libs="sdl-2.0 libressl curl maxminddb osx-cpu-temp sensors dlfcn-win32"

function build()
{
  BUILDSCRIPT=$1/build.sh

  for lib in "$@"; do

    script="$lib/build.sh"

    ## Linux ##

    TARGET=linux64 $script

    ## Windows ##

    TARGET=w32-clang $script
    TARGET=w64-clang $script

    ## FreeBSD ##

    HOSTPREFIX=amd64-pc-freebsd13.0 TARGET=freebsd64 $script
   done
}

USECLANG=1 ENABLE_LTO=1 build $libs
USECLANG=1 build $libs

./common/copy-lib-x.sh
