#!/usr/bin/env bash

PACKAGE="libressl"

. ${0%/*}/../common/common.inc.sh

download "libressl" "https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-3.2.3.tar.gz" \
  "" "sha256" "412dc2baa739228c7779e93eb07cd645d5c964d2f2d837a9fd56db7498463d73"

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

if [ $ISOSX -eq 1 ] && [[ "$TARGET" != *64h ]]; then
  # not supported until 10.12.1
  export ac_cv_func_timingsafe_bcmp=no
fi

extract_archives

pushd libressl*
echo_action "building libressl"
./configure --prefix=$TARGET_DIR $CONFIGURE_FLAGS
sed -i'' -e "s/apps //g" Makefile
sed -i'' -e "s/libcompatnoopt_la_CFLAGS = -O0/libcompatnoopt_la_CFLAGS = -O0 $ARCHFLAG/g" \
 crypto/Makefile
sed -i'' -e "s/ tests//g" Makefile
sed -i'' -e "s/ appsman//g" Makefile
$MAKE -j $JOBS install
popd

finish_libs
