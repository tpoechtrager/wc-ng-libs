#!/usr/bin/env bash

PACKAGE="libressl"

. ${0%/*}/../common/common.inc.sh

download "libressl" "https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-3.1.0.tar.gz" \
  "" "sha256" "f91aad0c8fb9cbc67c910ad6dcffb401a819b4fd122007ea7f978638db044cf6"

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
sed -i'' -e "s/ tests//g" Makefile
sed -i'' -e "s/ appsman//g" Makefile
$MAKE -j $JOBS install
popd

finish_libs
