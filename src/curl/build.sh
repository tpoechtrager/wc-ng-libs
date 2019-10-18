#!/usr/bin/env bash

PACKAGE="curl"

. ${0%/*}/../common/common.inc.sh

if [ -z "$SSLLIB" ]; then
    SSLLIB="openssl"
fi

if [ ! -e "$TARGET_DIR/lib/libcrypto.a" ]; then
    sh -c "$ROOTDIR/$SSLLIB/build.sh"
fi

download "curl" "http://curl.haxx.se/download/curl-7.66.0.tar.gz" \
  "" "sha256" "d0393da38ac74ffac67313072d7fe75b1fa1010eb5987f63f349b024a36b7ffb"

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
    --without-librtmp \
    --without-brotli \
    --without-libidn2 \
    --without-winidn \
    --without-libpsl
pushd lib
$MAKE -j $JOBS install
popd
popd

finish_libs
