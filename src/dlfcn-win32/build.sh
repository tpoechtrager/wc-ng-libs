#!/usr/bin/env bash

PACKAGE="dlfcn-win32"

PACKAGE_TARGETS="mingw32 mingw64 w32-clang w64-clang"

. ${0%/*}/../common/common.inc.sh

download "dlfcn-win32" "https://github.com/dlfcn-win32/dlfcn-win32/archive/v1.0.0.tar.gz" \
  "dlfcn-win32.tar.gz" "sha256" "36f2e7ef1f1ba04f6ce682a71937eaddd3d6994f09e29df2c7578ec524e47450"

extract_archives

pushd dlfcn*
echo_action "building dlfcn-win32"
patch -p0 -l < $PATCH_DIR/dlfcn.patch
[ -n "$HOST" ] && CROSSPREFIX="--cross-prefix=$HOST-"
./configure --prefix=$TARGET_DIR $CROSSPREFIX --cc=$CC
$MAKE -j $JOBS CC="$CC $CFLAGS"
$INSTALL -p -D libdl.a $TARGET_DIR/lib/libdl.a
$INSTALL -p -D dlfcn.h $TARGET_DIR/include/dlfcn.h
popd

finish_libs
