#!/usr/bin/env bash

PACKAGE="config4cpp"

. ${0%/*}/../common/common.inc.sh

download "config4cpp" "http://www.config4star.org/download/config4cpp.tar.gz" \
  "" "sha256" "74000384130097a2478dde56e4eb49c756f034b37da94826e5c58a37c6a06def"

extract_archives

pushd config4cpp*
echo_action "building config4cpp"

if [ $ISMINGW -eq 1 ]; then
    sed -i'' -e "s/-fPIC//g" Makefile.inc
fi

pushd src

sed -i'' -e 's/config2cpp-nocheck$(EXE_EXT)//g' Makefile
sed -i'' -e 's/cp config4cpp$(EXE_EXT) $(BIN_DIR)//g' Makefile
sed -i'' -e 's/cp config2cpp$(EXE_EXT) $(BIN_DIR)//g' Makefile

make \
     CC="$CC $CFLAGS" \
     CXX="$CXX -Wno-deprecated $CXXFLAGS" \
     AR=$AR RANLIB=$RANLIB

mkdir -pp $TARGET_DIR/lib $TARGET_DIR/include
cp -v libconfig4cpp.a $TARGET_DIR/lib
cp -rv ../include/config4cpp $TARGET_DIR/include

popd
popd

finish_libs
