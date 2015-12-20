#!/usr/bin/env bash

PACKAGE="curl"

. ${0%/*}/../common/common.inc.sh

if [ -z "$SSLLIB" ]; then
    SSLLIB="libressl"
fi

if [ ! -e "$TARGET_DIR/lib/libssl.a" ]; then
    sh -c "$ROOTDIR/$SSLLIB/build.sh"
fi

download "curl" "http://curl.haxx.se/download/curl-7.46.0.tar.bz2" \
  "" "sha256" "b7d726cdd8ed4b6db0fa1b474a3c59ebbbe4dcd4c61ac5e7ade0e0270d3195ad"

if [ $ISMINGW -eq 1 ]; then
    CONFIGURE_FLAGS+=" --disable-shared --enable-static"
else
    CONFIGURE_FLAGS+=" --disable-shared --enable-static --with-pic"
fi

if [ $ISMINGW -eq 0 -a $ISFBSD -eq 0 ]; then
    LDFLAGS+=" -ldl"
fi

extract_archives

pushd curl*
echo_action "building curl"
LDFLAGS="$LDFLAGS" \
./configure --prefix=$TARGET_DIR $CONFIGURE_FLAGS \
    --enable-threaded-resolver \
    --disable-manual \
    --disable-ldap \
    --disable-ldaps \
    --disable-rtsp \
    --with-ssl \
    --without-libssh2 \
    --without-libidn \
    --without-librtmp
$MAKE -j $JOBS install
popd

finish_libs
