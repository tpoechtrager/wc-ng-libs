#!/usr/bin/env bash

PACKAGE="maxminddb"

. ${0%/*}/../common/common.inc.sh

download "maxminddb" "https://github.com/maxmind/libmaxminddb/releases/download/1.3.2/libmaxminddb-1.3.2.tar.gz" \
  "libmaxminddb-1.3.2.tar.gz" "sha256" "e6f881aa6bd8cfa154a44d965450620df1f714c6dc9dd9971ad98f6e04f6c0f0"

if [ $ISMINGW -eq 1 ]; then
    CONFIGURE_FLAGS+=" --disable-shared --enable-static"
else
    CONFIGURE_FLAGS+=" --disable-shared --enable-static --with-pic"
fi

extract_archives

pushd libmaxminddb*
echo_action "building maxminddb"
./configure --prefix=$TARGET_DIR $CONFIGURE_FLAGS
pushd src
$MAKE -j $JOBS install
popd
popd

finish_libs
