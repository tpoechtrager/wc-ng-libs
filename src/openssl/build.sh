#!/usr/bin/env bash

PACKAGE="openssl"

. ${0%/*}/../common/common.inc.sh

download "openssl" "https://www.openssl.org/source/openssl-1.0.2e.tar.gz" \
  "" "sha256" "e23ccafdb75cfcde782da0151731aa2185195ac745eea3846133f2e05c0e0bff"

CONFIGURE_FLAGS="no-shared no-idea no-mdc2 no-rc4 no-rc5 no-zlib enable-tlsext no-ssl2 "

if [ $ISMINGW -eq 1 ]; then
    if [ $IS64BIT -eq 1 ]; then
        CONFIGURE_FLAGS+="mingw64"
    else
        CONFIGURE_FLAGS+="mingw"
    fi
elif [ $ISLINUX -eq 1 ]; then
    if [ $IS64BIT -eq 1 ]; then
        CONFIGURE_FLAGS+="linux-x86_64"
    else
        CONFIGURE_FLAGS+="debug-linux-generic32"
    fi
elif [ $ISIOS -eq 1 ]; then
    if [ $ISARMV6 -eq 1 -o $ISARMV7 -eq 1 -o $ISARMV7S -eq 1 ]; then
        CONFIGURE_FLAGS+="BSD-generic32"
    elif [ $ISARM64 ]; then
        CONFIGURE_FLAGS+="BSD-generic64"
    else
        exit 1
    fi
elif [ $ISOSX -eq 1 ]; then
    if [ $IS64BIT -eq 1 ]; then
        CONFIGURE_FLAGS+="darwin64-x86_64-cc"
    else
        CONFIGURE_FLAGS+="darwin-i386-cc"
    fi
elif [ $ISFBSD -eq 1 ]; then
    if [ $IS64BIT -eq 1 ]; then
        CONFIGURE_FLAGS+="BSD-x86_64"
    else
        CONFIGURE_FLAGS+="BSD-x86"
    fi
fi

if [ -n "$HOST" ]; then
    export CROSS_COMPILE="${HOST}-"
fi

CC="$CC $ARCHFLAG"

if [ -z "$AR" ]; then
    AR="ar"
fi

if [ $ISWCLANG -eq 1 ]; then
    CC+=" -no-integrated-as"
fi

CC+=" $CFLAGS"

extract_archives

pushd openssl*
echo_action "building openssl"
if [ $ISMINGW -eq 1 ]; then
  sed -i'' -e "s/ _stdcall/ __stdcall/g" engines/vendor_defns/cswift.h
fi
./Configure $CONFIGURE_FLAGS --prefix=$TARGET_DIR ${CFLAGS/$ARCHFLAG/}
#$MAKE depend || true
$MAKE CC="$CC" AR="$AR r" RANLIB="$RANLIB" -j 1 install
popd

finish_libs
