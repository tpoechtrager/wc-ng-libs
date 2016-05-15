#!/usr/bin/env bash

PACKAGE="curl"

. ${0%/*}/../common/common.inc.sh

if [ -z "$SSLLIB" ]; then
    SSLLIB="libressl"
fi

if [ ! -e "$TARGET_DIR/lib/libssl.a" ]; then
    sh -c "$ROOTDIR/$SSLLIB/build.sh"
fi

download "curl" "http://curl.haxx.se/download/curl-7.48.0.tar.bz2" \
  "" "sha256" "864e7819210b586d42c674a1fdd577ce75a78b3dda64c63565abe5aefd72c753"

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
patch -p0 < $PATCH_DIR/libressl.patch
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
