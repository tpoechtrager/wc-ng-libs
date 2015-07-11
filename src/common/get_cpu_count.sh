#!/usr/bin/env bash

: CC=${CC:=cc}

prog="cpucount"

pushd "${0%/*}" &>/dev/null

case "$(uname -s)" in
  *NT*)
    prog="${prog}.exe" ;;
esac

test -f "${prog}" || $CC cpucount.c -o $prog || exit 1

eval "./${prog}"
