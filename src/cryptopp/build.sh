#!/usr/bin/env bash

PACKAGE="cryptopp"

. ${0%/*}/../common/common.inc.sh

download "cryptopp" "https://github.com/weidai11/cryptopp/archive/CRYPTOPP_8_2_0.tar.gz" \
  "" "sha256" "e3bcd48a62739ad179ad8064b523346abb53767bcbefc01fe37303412292343e"

extract_archives

pushd cryptopp*
echo_action "building cryptopp"

if [ $ISLINUX -eq 1 -a $ISARMV7 -eq 1 ]; then
    export LDFLAGS+="-latomic"
fi

if [ $ISMINGW -eq 1 -a $ISWCLANG -eq 0 ] || [ $ISLINUX -eq 1 -a $IS32BIT -eq 1 ]; then
    export CXX+=" -DCRYPTOPP_DISABLE_SSSE3 -DCRYPTOPP_DISABLE_SSE4 -DCRYPTOPP_DISABLE_SSE4"
fi

if [ $ISLINUX -eq 1 -o $ISFBSD -eq 1 -o $ISOSX -eq 1 ]; then
if [ $IS64BIT ]; then
    export CXX+=" -DCRYPTOPP_DISABLE_ASM"
fi
fi


if [ $ISWCLANG -eq 1 ]; then
  export CXX+=" -DCRYPTOPP_DISABLE_ASM"
  export LDFLAGS+=" -pthread"
fi

if [ $ISIOS -eq 1 ]; then
  sed -i'' -e "s/SRCS += aes_armv4.S//g" GNUmakefile-cross
fi

make -f GNUmakefile-cross \
  install \
  -j $JOBS \
  PREFIX=$TARGET_DIR

mkdir -p $TARGET_DIR/lib
$INSTALL -p -D libcryptopp.a $TARGET_DIR/lib

popd

finish_libs
