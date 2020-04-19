#!/usr/bin/env bash

set -e

if [ $(uname -s) == "Darwin" ]; then
    LIPO=lipo
    AR=ar
else
    eval $(osxcross-conf)
    LIPO=x86_64-apple-${OSXCROSS_TARGET}-lipo
    AR=x86_64-apple-${OSXCROSS_TARGET}-ar
fi

TARGET=osx32 ./$1/build.sh
TARGET=osx64 ./$1/build.sh
TARGET=osx64h ./$1/build.sh

if [ -n "$ENABLE_LTO" ]; then
    SUFFIX+="_lto"
fi

pushd target
mkdir -p osx-fat${SUFFIX}/lib

if [ -n "$USECLANG" ] && [ -n "$ENABLE_LTO" ] && [ 0 -ne 0 ]; then
    mkdir -p osx-fat osx-fat/lib osx32/lib osx64/lib
    bc2obj osx32_lto/lib/*.a -out-dir osx32/lib -pic -ar=$AR
    bc2obj osx64_lto/lib/*.a -out-dir osx64/lib -pic -ar=$AR
    bc2obj osx64h_lto/lib/*.a -out-dir osx64h/lib -pic -ar=$AR

    for f in osx32/lib/*.a
    do
        lib=$(basename $f)
        echo "lipo'ing $lib (native)"
        $LIPO -create osx32/lib/$lib osx64/lib/$lib osx64h/lib/$lib \
          -output "osx-fat/lib/$lib"
    done
fi

for f in osx32${SUFFIX}/lib/*.a
do
    lib=$(basename $f)
    echo "lipo'ing $lib"
    $LIPO -create \
      osx32${SUFFIX}/lib/$lib \
      osx64${SUFFIX}/lib/$lib \
      osx64h${SUFFIX}/lib/$lib \
      -output "osx-fat${SUFFIX}/lib/$lib"
done
