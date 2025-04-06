#!/usr/bin/env bash

PACKAGE="zlib"

. ${0%/*}/../common/common.inc.sh

download "zlib" "https://zlib.net/zlib-1.3.1.tar.gz" \
 "" "sha256" "9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23"

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
