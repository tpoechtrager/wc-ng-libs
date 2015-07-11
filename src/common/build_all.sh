#!/usr/bin/env bash

set -e

BUILDSCRIPT=$1/build.sh

unset CC CXX
export USECLANG=1
export ENABLE_LTO=1

## TODO: require bc2obj

for lib in "$@"; do

script="$lib/build.sh"

## Linux ##

TARGET=linux32 $script
TARGET=linux64 $script

mkdir -p target/linux32/lib target/linux64/lib
bc2obj target/linux32_lto/lib/*.a -out-dir target/linux32/lib -pic
bc2obj target/linux64_lto/lib/*.a -out-dir target/linux64/lib -pic

## Windows ##

TARGET=w32-clang $script
TARGET=w64-clang $script

mkdir -p target/w32-clang target/w32-clang/lib target/w64-clang target/w64-clang/lib
bc2obj target/w32-clang_lto/lib/*.a -out-dir target/w32-clang/lib
bc2obj target/w64-clang_lto/lib/*.a -out-dir target/w64-clang/lib

## Darwin ##

./common/build_osx_fat.sh $lib

## FreeBSD ##

HOSTPREFIX=amd64-pc-freebsd10.1 TARGET=freebsd64 $script
mkdir -p target/freebsd64/lib
bc2obj target/freebsd64_lto/lib/*.a -out-dir target/freebsd64/lib -pic

done
