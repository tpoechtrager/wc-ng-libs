#!/usr/bin/env bash

set -e

pushd "${0%/*}" &>/dev/null

unset ENABLE_LTO
unset HOSTPREFIX
unset CC CXX
unset USECLANG

rm -rf target build

libraries=("zlib" "sdl-2.0" "libressl" "curl" "maxminddb" "osx-cpu-temp" "sensors" "dlfcn-win32")
targets=("linux64" "w32-clang" "w64-clang")

child_pids=()

function cleanup() {
  echo "Cleanup: killing background processes..."
  for pid in "${child_pids[@]}"; do
    kill -TERM "$pid" 2>/dev/null || true
  done
  wait
  exit 1
}

trap cleanup SIGINT SIGTERM

function build_libraries() {
  local library target script
  for library in "${libraries[@]}"; do
    script="$library/build.sh"
    local target_pids=()
    for target in "${targets[@]}"; do
      TARGET=$target "$script" &
      target_pids+=($!)
    done
    for pid in "${target_pids[@]}"; do
      wait "$pid" || return 1
    done
  done
}

# Run LTO build in background
(
  USECLANG=1 ENABLE_LTO=1 build_libraries
) &
pid_lto=$!
child_pids+=($pid_lto)

# Run non-LTO build in background
(
  USECLANG=1 build_libraries
) &
pid_nolto=$!
child_pids+=($pid_nolto)

# Wait and fail fast
wait $pid_lto || cleanup
wait $pid_nolto || cleanup

./common/copy-lib-x.sh
