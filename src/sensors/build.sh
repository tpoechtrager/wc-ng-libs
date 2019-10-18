#!/usr/bin/env bash

PACKAGE="sensors"
PACKAGE_TARGETS="linux32 linux64"

. ${0%/*}/../common/common.inc.sh

have_prog "flex" 1
have_prog "bison" 1

download "sensors" "https://ftp.gwdg.de/pub/linux/misc/lm-sensors/lm_sensors-3.4.0.tar.bz2" \
  "" "sha256" "e0579016081a262dd23eafe1d22b41ebde78921e73a1dcef71e05e424340061f"

extract_archives

pushd lm_sensors*
echo_action "building sensors"
$MAKE -j $JOBS CC=$CC PREFIX=$TARGET_DIR CFLAGS="$CFLAGS -fPIC" LDFLAGS="$LDFLAGS -fPIC" SRCDIRS=lib install
popd

finish_libs
