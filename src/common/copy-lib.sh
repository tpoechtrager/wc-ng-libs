#!/usr/bin/env bash

pushd "${0%/*}/../target" &>/dev/null

LIB=$1
LIBDIR=$PWD/../..

function strip_lib()
{
    set -e

    echo "stripping $2"

    case $1 in
        *osx*)
            xcrun strip $2 2>/dev/null || true  ;;
        *ios*)
            arm-apple-darwin11-strip $2 ;;
        freebsd64)
            amd64-pc-freebsd10.1-strip --strip-unneeded $2 ;;
        mingw32 | w32-clang)
            i686-w64-mingw32-strip --strip-unneeded $2 ;;
        mingw64 | w64-clang)
            x86_64-w64-mingw32-strip --strip-unneeded $2 ;;
        linux*)
            strip --strip-unneeded $2 ;;
        *)
            echo "unknown lib type ($1)"
            exit 1 ;;
    esac

    set +e
}

function fix_llvm_ar()
{
    echo "fixing llvm ar ($1)"

    pushd $(dirname $1) &>/dev/null
    ar x $(basename $1)
    RANLIB=true llvm-ar rcs $(basename $1) *o
    if [[ $1 == *win/* ]]; then
      # FIXME: This is dumb.
      if [[ $1 == *win/x86_64* ]]; then
        x86_64-w64-mingw32-ranlib $(basename $1)
      else
        i686-w64-mingw32-ranlib $(basename $1)
      fi
    fi
    rm -f *.o *.ao
    popd &>/dev/null
}

function copy()
{
   local a="$1/lib/$LIB"
   local b="$LIBDIR/$2/$LIB"

   if [ -e $a ]; then
      echo "copying $a -> $b"
      cp $a $b

      if [[ $b == *llvm-lto* ]] && [[ $b != *darwin* ]]; then
          fix_llvm_ar $b
      else
          strip_lib $1 $b
      fi
   fi
}

copy linux32 linux/i686/native
copy linux64 linux/x86_64/native

copy linux32_lto linux/i686/llvm-lto
copy linux64_lto linux/x86_64/llvm-lto

copy osx-fat darwin/native
copy osx-fat_lto darwin/llvm-lto

copy mingw32 win/i686/native
copy mingw64 win/x86_64/native

copy w32-clang win/i686/native
copy w64-clang win/x86_64/native

copy w32-clang_lto win/i686/llvm-lto
copy w64-clang_lto win/x86_64/llvm-lto

copy freebsd64 freebsd/amd64/native
copy freebsd64_lto freebsd/amd64/llvm-lto


