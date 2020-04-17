#!/usr/bin/env bash

set -e

BUILDSCRIPT=$1/build.sh

unset CC CXX

for lib in "$@"; do

script="$lib/build.sh"

## Linux ##

TARGET=linux32 $script
TARGET=linux64 $script

## Windows ##

TARGET=w32-clang $script
TARGET=w64-clang $script

## Darwin ##

./common/build_osx_fat.sh $lib

## FreeBSD ##

USECLANG=1 HOSTPREFIX=amd64-pc-freebsd13.0 TARGET=freebsd64 $script

done
