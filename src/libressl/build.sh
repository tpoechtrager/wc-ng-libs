#!/usr/bin/env bash

PACKAGE="libressl"

. ${0%/*}/../common/common.inc.sh

download "libressl" "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-3.0.1.tar.gz" \
  "" "sha256" "646adb1197fbe3a7542f18843d2b4adf857b77e50bb878b58f4e7dde5b7343cb"

if [ $ISMINGW -eq 1 ]; then
    CONFIGURE_FLAGS+=" --disable-shared --enable-static"
else
    CONFIGURE_FLAGS+=" --disable-shared --enable-static --with-pic"
fi

if [ -z "$HOSTPREFIX" ]; then
if [ $IS32BIT -eq 1 ]; then
	CONFIGURE_FLAGS+=" --host=i686-unknown-$PLATFORM_LC"
elif [ $IS64BIT -eq 1 ]; then
	CONFIGURE_FLAGS+=" --host=x86_64-unknown-$PLATFORM_LC"
fi
fi

extract_archives

pushd libressl*
echo_action "building libressl"
./configure --prefix=$TARGET_DIR $CONFIGURE_FLAGS
sed -i'' -e "s/libcompatnoopt_la_CFLAGS = -O0/libcompatnoopt_la_CFLAGS = -O0 $ARCHFLAG/g" \
 crypto/Makefile
$MAKE -j $JOBS install
popd

finish_libs
