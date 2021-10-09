#!/usr/bin/env bash

PACKAGE="zlib"

. ${0%/*}/../common/common.inc.sh

download "zlib" "http://zlib.net/zlib-1.2.11.tar.gz" \
 "" "sha256" "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1"

extract_archives


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


finish_libs
