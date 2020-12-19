#!/usr/bin/env bash

PACKAGE="zlib"

. ${0%/*}/../common/common.inc.sh

download "curl" "https://github.com/tpoechtrager/zlib-ng/archive/develop.tar.gz" \
  "" "" ""

extract_archives


echo_action "building zlib"
pushd zlib*
if [ $ISMINGW -ne 1 ]; then
    export CFLAGS="$CFLAGS -fPIC"
fi
./configure --zlib-compat --static
$MAKE -j $JOBS
mkdir -p $TARGET_DIR/lib $TARGET_DIR/include
$INSTALL -p -D libz.a $TARGET_DIR/lib/libz.a
$INSTALL -p -D zlib.h zconf.h $TARGET_DIR/include
popd

finish_libs
