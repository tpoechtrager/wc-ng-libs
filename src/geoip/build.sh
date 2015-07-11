#!/usr/bin/env bash

PACKAGE="geoip"

. ${0%/*}/../common/common.inc.sh

download "GeoIP" "https://github.com/maxmind/geoip-api-c/releases/download/v1.6.5/GeoIP-1.6.5.tar.gz" \
  "GeoIP-1.6.5.tar.gz" "sha256" "0ae1c95e69ad627d3a45cb897f79ce0c30f13fcd4b4a0dda073be0c9552521b3"

if [ $ISMINGW -eq 1 ]; then
    CONFIGURE_FLAGS+=" --disable-shared --enable-static"
else
    CONFIGURE_FLAGS+=" --disable-shared --enable-static --with-pic"
fi

extract_archives

pushd GeoIP*
echo_action "building geoip"
patch -p0 < $PATCH_DIR/geoip-malloc.patch
patch -p0 < $PATCH_DIR/geoip-libs_only.patch
autoreconf -fi
./configure --prefix=$TARGET_DIR $CONFIGURE_FLAGS
$MAKE -j $JOBS install
popd

finish_libs
