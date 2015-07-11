#!/usr/bin/env bash

PACKAGE="sensors"
PACKAGE_TARGETS="linux32 linux64"

. ${0%/*}/../common/common.inc.sh

have_prog "flex" 1
have_prog "bison" 1

download "sensors" "http://dl.lm-sensors.org/lm-sensors/releases/lm_sensors-3.3.5.tar.bz2" \
  "" "sha256" "5dae6a665e1150159a93743c4ff1943a7efe02cd9d3bb12c4805e7d7adcf4fcf"

extract_archives

pushd lm_sensors*
echo_action "building sensors"
$MAKE -j $JOBS CC=$CC PREFIX=$TARGET_DIR CFLAGS="$CFLAGS -fPIC" LDFLAGS="$LDFLAGS -fPIC" SRCDIRS=lib install
popd

finish_libs
