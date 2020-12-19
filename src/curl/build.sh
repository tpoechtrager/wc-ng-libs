#!/usr/bin/env bash

PACKAGE="curl"

. ${0%/*}/../common/common.inc.sh

if [ -z "$HUAWEI_TOOL" ]; then
    if [ -z "$SSLLIB" ]; then
        SSLLIB="libressl"
    fi

    if [ ! -e "$TARGET_DIR/lib/libcrypto.a" ]; then
        sh -c "$ROOTDIR/$SSLLIB/build.sh"
    fi

    CONFIGURE_FLAGS+=" --with-ssl"
else
    CONFIGURE_FLAGS+=" --without-ssl"
fi

download "curl" "http://curl.haxx.se/download/curl-7.74.0.tar.gz" \
  "" "sha256" "e56b3921eeb7a2951959c02db0912b5fcd5fdba5aca071da819e1accf338bbd7"

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
if [ $ISOSX -eq 1 -a $ISCLANG -eq 1 ]; then
    # get rid of __isOSVersionAtLeast()
    CC="$CC -D__builtin_available\\(...\\)=0"
fi
CC="$CC -pthread" \
LDFLAGS="$LDFLAGS" \
./configure \
    --prefix=$TARGET_DIR \
    --enable-threaded-resolver \
    --disable-manual \
    --disable-ldap \
    --disable-ldaps \
    --disable-rtsp \
    --without-libssh2 \
    --without-libidn \
    --without-librtmp \
    --without-brotli \
    --without-libidn2 \
    --without-winidn \
    --without-libpsl \
    --without-zstd \
    $CONFIGURE_FLAGS
pushd lib
$MAKE -j $JOBS install
popd
popd

finish_libs
