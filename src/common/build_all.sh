#!/usr/bin/env bash

set -e

BUILDSCRIPT=$1/build.sh

unset CC CXX

for lib in "$@"; do

script="$lib/build.sh"

## Linux ##

TARGET=linux32 $script
TARGET=linux64 $script

mkdir -p target/linux32/lib target/linux64/lib

## Windows ##

TARGET=mingw32 $script
TARGET=mingw64 $script

## Darwin ##

./common/build_osx_fat.sh $lib

## FreeBSD ##

USECLANG=1 HOSTPREFIX=amd64-pc-freebsd10.1 TARGET=freebsd64 $script

done
