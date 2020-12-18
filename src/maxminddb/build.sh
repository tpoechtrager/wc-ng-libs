#!/usr/bin/env bash

PACKAGE="maxminddb"

. ${0%/*}/../common/common.inc.sh

download "maxminddb" "https://github.com/maxmind/libmaxminddb/releases/download/1.4.3/libmaxminddb-1.4.3.tar.gz" \
  "libmaxminddb-1.4.3.tar.gz" "sha256" "a5fdf6c7b4880fdc7620f8ace5bd5cbe9f65650c9493034b5b9fc7d83551a439"

if [ $ISMINGW -eq 1 ]; then
    CONFIGURE_FLAGS+=" --disable-shared --enable-static"
else
    CONFIGURE_FLAGS+=" --disable-shared --enable-static --with-pic"
fi

extract_archives

pushd libmaxminddb*
echo_action "building maxminddb"
./configure --prefix=$TARGET_DIR $CONFIGURE_FLAGS
echo "#undef MMDB_UINT128_USING_MODE"       >> include/maxminddb_config.h
echo "#undef MMDB_UINT128_IS_BYTE_ARRAY"    >> include/maxminddb_config.h
echo "#define MMDB_UINT128_USING_MODE 0"    >> include/maxminddb_config.h
echo "#define MMDB_UINT128_IS_BYTE_ARRAY 1" >> include/maxminddb_config.h
pushd src
$MAKE -j $JOBS install
popd
popd

finish_libs
