#!/usr/bin/env bash

PACKAGE="maxminddb"

. ${0%/*}/../common/common.inc.sh

download "maxminddb" "https://github.com/maxmind/libmaxminddb/releases/download/1.12.2/libmaxminddb-1.12.2.tar.gz" \
  "libmaxminddb-1.12.2.tar.gz" "sha256" "1bfbf8efba3ed6462e04e225906ad5ce5fe958aa3d626a1235b2a2253d600743"

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
