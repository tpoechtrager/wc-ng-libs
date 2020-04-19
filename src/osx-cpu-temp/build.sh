#!/usr/bin/env bash

PACKAGE="osx-cpu-temp"

PACKAGE_TARGETS="osx32 osx64 osx64h"

. ${0%/*}/../common/common.inc.sh


download "osx-cpu-temp" "https://github.com/tpoechtrager/osx-cpu-temp/archive/2020-04-17.tar.gz" \
  "" "sha256" "30c2b9fba1435d5d24c21224f649056cad5f028e3660d3b10dda7dab8d703a30"

extract_archives

mkdir -p $TARGET_DIR/include/osx-cpu-temp

pushd osx-cpu-temp*
make CC="$CC" CFLAGS="$CFLAGS" AR="$AR" TARGETS=""
cp -v smc.a $TARGET_DIR/lib
cp -v smc.h $TARGET_DIR/include/osx-cpu-temp
popd

finish_libs
