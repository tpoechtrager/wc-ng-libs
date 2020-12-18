#!/usr/bin/env bash

PACKAGE="sensors"
PACKAGE_TARGETS="linux32 linux64"

. ${0%/*}/../common/common.inc.sh

have_prog "flex" 1
have_prog "bison" 1

download "sensors" "https://github.com/lm-sensors/lm-sensors/archive/V3-6-0/lm-sensors-3-6-0.tar.gz" \
  "" "sha256" "0591f9fa0339f0d15e75326d0365871c2d4e2ed8aa1ff759b3a55d3734b7d197"

extract_archives

pushd lm-sensors*
echo_action "building sensors"
$MAKE -j $JOBS CC=$CC PREFIX=$TARGET_DIR CFLAGS="$CFLAGS -fPIC" LDFLAGS="$LDFLAGS -fPIC" SRCDIRS=lib install
popd

finish_libs
