set -e

function echo_bold()
{
    if [ $IS_TERMINAL -eq 1 ]; then
        echo -e "\e[1m${1}\e[0m"
    else
        echo -e "$1"
    fi
}

function echo_yellow()
{
    if [ $IS_TERMINAL -eq 1 ]; then
        echo -e "\e[1m\e[33m${1}\e[0m"
    else
        echo -e "$1"
    fi
}

function echo_red()
{
    if [ $IS_TERMINAL -eq 1 ]; then
        echo -e "\e[1m\e[31m${1}\e[0m"
    else
        echo -e "$1"
    fi
}

function echo_action()
{
    echo_bold "\n*** $1 ***\n"
}

function echo_warning()
{
    echo_yellow "warning: $1" 1>&2
}

function echo_error()
{
    echo_red "error: $1" 1>&2
}

function implode()
{
    local glue
    local result
    declare -i i=0
    declare -a input=("${!2}")

    for ((i=0; i<${#input[@]}; i++)); do
        result+="${glue}${input[$i]}"
        test -z "$glue" && glue="$1"
    done

    echo -n "$result"
}

function exec_silent()
{
    set +e

    OUTPUT=$($* 2>&1)

    if [ $? -ne 0 ]; then
        echo_error "$OUTPUT"
        exit 1
    fi

    set -e
}

function have_prog()
{
    test -z "$1" && return 1

    local have=0
    local prog=`echo -n "$1" | tr '[:lower:]' '[:upper:]' | tr -cd '[:alnum:]'`
    declare -i required="$2"

    have=$(which "$1" &>/dev/null && echo 1 || echo 0)

    eval "HAVE_${prog}"=$have

    if [ "$have" -eq 0 -a $required -ne 0 ]; then
        echo_error "'$1' is required to build '$PACKAGE'"
        exit 1
    fi
}

function download()
{
    pushd $SOURCES_DIR &>/dev/null

    declare -i have=0
    local wget_opts="--trust-server-names --continue"

    if [ $ISNATIVEBSD -eq 1 ]; then
        wget_opts+=" --ca-certificate /usr/local/share/certs/ca-root-nss.crt"
    fi

    [ -n "$3" ] && wget_opts+=" -O $3"

    if [ -f .sources ]; then
        for s in $(cat .sources); do
            if [ "$s" == "$2" ]; then
                have=1
                break
            fi
        done
    fi

    if [ $have -ne 1 ]; then
        rm -rf *$1*
        if [ $IS_TERMINAL -ne 1 ]; then
            wget_opts+=" --quiet"
            echo_bold "downloading $2"
        fi

        wget $wget_opts "$2"

        if [ -n "$4" ]; then
            have_prog "openssl" 1

            local filename

            if [ -n "$3" ]; then
                filename=$(basename $3)
            else
                filename=$(basename $2)
            fi

            local filehash=$(openssl $4 $filename | awk '{print $2}')

            if [ "$filehash" != "$5" ]; then
                echo_red "$filename: file integrity verification failed!"
                echo_bold "expected ($4): $5, got: $filehash"
                exit 1
            fi
        fi

        echo "$2" >> .sources
    fi

    popd &>/dev/null
}

function extract_archive()
{
    local archive="$1"

    if [ ! -f $archive ]; then
        echo_error "cannot open archive '$archive'"
        exit 1
    fi

    echo_bold "extracting: $archive"

    case $archive in
        *.tgz|*.tbz|*.tar.gz|*.tar.bz2|*.tar.xz)
            tar xf $archive ;;
        *)
            echo_error "unsupported archive type '$archive'"
            exit 1
    esac
}

function extract_archives()
{
    echo_action "extracting sources"

    local f

    for f in $SOURCES_DIR/*
    do
        extract_archive "$f"
    done
}

function finish_libs()
{
    true
}

function gcc_greater_equal()
{
    have_prog "bc" 1

    local version_a
    local version_b

    [ $ISGCC -ne 1 ] && echo 0 && exit 0

    version_a=$(echo $GCC_VERSION | tr '.' ' ' | awk '{printf "%d.%d", $1, $2}')
    version_b=$(echo $1 | tr '.' ' ' | awk '{printf "%d.%d", $1, $2}')

    echo $(echo "$version_a>=$version_b" | bc -l)
}

export LC_ALL="C"

if [ -t 1 ]; then
    IS_TERMINAL=1
else
    IS_TERMINAL=0
fi

if [ -z "$TARGET" ]; then
    echo "TARGET must be set!"
    echo "supported targets:"
    echo " linux32 linux64"
    echo " osx32 osx64"
    echo " ios-armXX"
    echo " freebsd32 freebsd64"
    echo " mingw32 mingw64"
    echo " w32-clang w64-clang"
    exit 1
fi

ISLINUX=0
ISOSX=0
ISIOS=0
ISFBSD=0
ISMINGW=0
ISWCLANG=0

case $TARGET in
    linux32|linux64)
        PLATFORM="Linux"
        ISLINUX=1 ;;
    osx32|osx64|osx64h)
        PLATFORM="Darwin"
        ISOSX=1 ;;
    ios-arm*)
        PLATFORM="Darwin"
        ISOSX=1
        ISIOS=1 ;;
    freebsd32|freebsd64)
        PLATFORM="FreeBSD"
        ISFBSD=1 ;;
    mingw32|mingw64)
        PLATFORM="MINGW"
        ISMINGW=1 ;;
    w32-clang|w64-clang)
        PLATFORM="MINGW"
        ISMINGW=1
        ISWCLANG=1 ;;
    *)
        echo_error "invalid TARGET '$TARGET'"
        exit 1 ;;
esac

if [ -n "$USECLANG" ]; then
    CC_NATIVE=clang
    CXX_NATIVE=clang++
else
    CC_NATIVE=gcc
    CXX_NATIVE=g++
fi

if [ -n "$PACKAGE_TARGETS" ]; then
    if [ "${PACKAGE_TARGETS/$TARGET/}" == "$PACKAGE_TARGETS" ]; then
        echo_warning "PACKAGE $PACKAGE doesn't support TARGET $TARGET"
        exit 0
    fi
fi

if [ -n "$ENABLE_LTO" ]; then
    SUFFIX+="_lto"
fi

if [ -z "$DEBUG" ]; then
    CFLAGS+=" -O2"
    CXXFLAGS+=" -O2"
else
    CFLAGS+="-O0 -g3"
    CXXFLAGS+="-O0 -g3"
    SUFFIX+="_dbg"
fi


pushd ${0%/*}
ROOTDIR="$PWD/.."
PLATFORM_LC="`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`"
NATIVE_PLATFORM="`uname -s`"
PATCH_DIR="$PWD/patches"
BASE_DIR="$ROOTDIR/build/$PACKAGE"
mkdir -p $BASE_DIR
pushd $BASE_DIR
BUILD_DIR="$PWD/build_${TARGET}${SUFFIX}"
SOURCES_DIR="$ROOTDIR/tarballs/$PACKAGE"
TARGET_DIR="$ROOTDIR/target/${TARGET}${SUFFIX}"
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
mkdir -p $TARGET_DIR
mkdir -p $SOURCES_DIR
export PATH="$PATH:$TARGET_DIR/bin"
export PKG_CONFIG=false

# unset variables that should not be set
unset INCLUDE

ISCROSS=0
STRIP=strip
RANLIB=ranlib
CROSSTOOLS=""
CONFIGURE_FLAGS="--libdir=$TARGET_DIR/lib --enable-static --disable-shared"
FLAVOUR=()
JOBS=${JOBS:=$(../../common/get_cpu_count.sh)}

ARCHFLAG=""
IS32BIT=0
IS64BIT=0
ISARMV6=0
ISARMV7=0
ISARMV7S=0
ISARM64=0

if [[ "$TARGET" == *armv6 ]]; then
    ARCHFLAG="-arch armv6"
    ISARMV6=1
elif [[ "$TARGET" == *armv7s ]]; then
    ARCHFLAG="-arch armv7s"
    ISARMV7S=1
elif [[ "$TARGET" == *armv7 ]]; then
    ARCHFLAG="-arch armv7"
    ISARMV7=1
elif [[ "$TARGET" == *arm64 ]]; then
    ARCHFLAG="-arch arm64"
    ISARM64=1
elif [[ "$TARGET" == *64h ]]; then
    ARCHFLAG="-arch x86_64h"
    IS64BIT=1
elif [[ "$TARGET" == *64* ]]; then
    ARCHFLAG="-m64"
    IS64BIT=1
elif [[ "$TARGET" == *32* ]]; then
    ARCHFLAG="-m32"
    IS32BIT=1
else
    echo_error "unknown architecture"
    exit 1
fi

CFLAGS+=" $ARCHFLAG"
CXXFLAGS+=" $ARCHFLAG"
LDFLAGS+=" $ARCHFLAG"

if [ $ISIOS -eq 1 ]; then
    CFLAGS+=" -mios-version-min=4.2"
    CXXFLAGS+=" -mios-version-min=4.2"
    LDFLAGS+=" -mios-version-min=4.2"
fi

if [ $ISWCLANG -ne 0 ]; then
    if [ "$TARGET" != "${TARGET/64/}" ]; then
        CC="w64-clang"
    else
        CC="w32-clang"
    fi

    HOSTPREFIX=`$CC -wc-target`
    CC="${HOSTPREFIX}-clang"
    CXX="${HOSTPREFIX}-clang++"

    if [ $? -ne 0 ]; then
        echo_error "couldn't determine wclang host"
        exit 1
    fi
else
    if [ $ISMINGW -ne 0 ] && [ -z "$HOSTPREFIX" ]; then
        if [ $IS64BIT -eq 1 ]; then
            HOSTPREFIX="x86_64-w64-mingw32"
        else
            HOSTPREFIX="i686-w64-mingw32"
        fi
    fi
fi

if [ $ISOSX -eq 1 ]; then
    export MACOSX_DEPLOYMENT_TARGET=10.5
fi

if [ $ISOSX -eq 1 -a $NATIVE_PLATFORM != "Darwin" -a -z "$HOSTPREFIX" ];
then

    if [ $ISIOS -ne 1 ]; then
        have_prog "osxcross-conf" 1
        eval `osxcross-conf`
 
        if [ $IS64BIT -eq 1 ]; then
            if [ -n "$USECLANG" ]; then
                CC="x86_64-apple-${OSXCROSS_TARGET}-clang"
                CXX="x86_64-apple-${OSXCROSS_TARGET}-clang++"
            else
                CC="x86_64-apple-${OSXCROSS_TARGET}-gcc"
                CXX="x86_64-apple-${OSXCROSS_TARGET}-g++"
            fi
            HOSTPREFIX="x86_64-apple-${OSXCROSS_TARGET}"
        else
            if [ -n "$USECLANG" ]; then
                CC="i386-apple-${OSXCROSS_TARGET}-clang"
                CXX="i386-apple-${OSXCROSS_TARGET}-clang++"
            else
                CC="i386-apple-${OSXCROSS_TARGET}-gcc"
                CXX="i386-apple-${OSXCROSS_TARGET}-g++"
            fi
            HOSTPREFIX="i386-apple-${OSXCROSS_TARGET}"
        fi
        ISOSXCROSS=1
    else
        CC="arm-apple-darwin11-clang"
        CXX="arm-apple-darwin11-clang++"
        HOSTPREFIX="arm-apple-darwin11"
    fi
else
    ISOSXCROSS=0
fi

if [ $NATIVE_PLATFORM == "Darwin" ] || [[ $NATIVE_PLATFORM == *BSD ]];
then
    have_prog "ginstall" 1
    have_prog "gmake" 1
    ISNATIVEBSD=1
    INSTALL=ginstall
    MAKE=gmake
else
    ISNATIVEBSD=0
    INSTALL=install
    MAKE=make
fi

if [ -n "$HOSTPREFIX" ]; then
    ISCROSS=1

    export LD="${HOSTPREFIX}-ld"
    export AR="${HOSTPREFIX}-ar"
    export RANLIB="${HOSTPREFIX}-ranlib"
    export STRIP="${HOSTPREFIX}-strip"

    which $LD &>/dev/null || {
        echo_error "invalid HOSTPREFIX '$HOSTPREFIX' given"
        exit 1
    }

    if [ $ISWCLANG -eq 0 -a $ISOSXCROSS -eq 0 ]; then

        if [ $ISMINGW -eq 0 -a -n "$USECLANG" ]; then
            CC="${HOSTPREFIX}-clang"
            CXX="${HOSTPREFIX}-clang++"
        fi

        set +e

        which "$CC" &>/dev/null
        if [ $? -ne 0 -o -z "$CC" -o -z "$USECLANG" ]; then
            CC="${HOSTPREFIX}-gcc"
            CXX="${HOSTPREFIX}-g++"
        fi

        set -e
    fi

    if [ -z "$CC" ]; then
        echo_error "CC not set"
        exit 1
    fi

    if [ -z "$CXX" ]; then
        echo_error "CXX not set"
        exit 1
    fi

    have_prog $CC 1
    have_prog $CXX 1

    test $ISMINGW -eq 1 && export LDFLAGS+=" -static-libgcc -static-libstdc++ "

    CROSSTOOLS="LD=$LD AR=$AR RANLIB=$RANLIB STRIP=$STRIP"

    CONFIGURE_FLAGS+=" --host=${HOSTPREFIX} "
    export CROSS="${HOSTPREFIX}-" # vpx
else
    if [ $PLATFORM != $NATIVE_PLATFORM ]; then
        echo_error "HOSTPREFIX must be set for target '$PLATFORM'"
        exit 1
    fi
fi

CFLAGS+=" -I$TARGET_DIR/include "
CXXFLAGS+=" -I$TARGET_DIR/include "
CPPFLAGS="$CPPFLAGS -I$TARGET_DIR/include" \
LDFLAGS+=" -L$TARGET_DIR/lib "

test -z "$CC" && CC=$CC_NATIVE
test -z "$CXX" && CXX=$CXX_NATIVE

if [[ "$CC" == *clang* ]]; then
    ISCLANG=1
    #CFLAGS+=" -no-integrated-as"
    #CXXFLAGS+=" -no-integrated-as"
else
    ISCLANG=0
fi

if [[ "$CC" == *gcc* ]]; then
    GCC_VERSION=$($CC -dumpversion)
    ISGCC=1
else
    ISGCC=0
fi

if [ -z "$HOSTPREFIX" ] && [ $ISCLANG -eq 1 ]; then
    GOLD=$(which ld.gold 2>/dev/null)
    if [ -n "$GOLD" ]; then
        ln -sf $GOLD $ROOTDIR/build/ld
        export COMPILER_PATH=$ROOTDIR/build
        export PATH=$ROOTDIR/build:$PATH
    fi
fi

if [ -n "$ENABLE_LTO" ]; then
    LTOFLAG="-flto"

    if [[ $CC == *icc* ]]; then
        LTOFLAG="-ipo"
    fi

    CFLAGS+=" $LTOFLAG"
    LDFLAGS+=" $LTOFLAG"
    CXXFLAGS+=" $LTOFLAG"

    if [ $(gcc_greater_equal 4.8) -eq 1 ]; then
        export CFLAGS+=" -ffat-lto-objects"
        export CXXFLAGS+=" -ffat-lto-objects"
    fi

    if [ $ISOSX -ne 1 ] && [[ $CC == *clang* ]] && [[ $ISMINGW -ne 1 ]]; then
        # FIXME: llvm-ar isn't in PATH on ubuntu.
        export AR=`which llvm-ar 2>/dev/null || echo /opt/compiler/llvm-trunk/bin/llvm-ar`
        export RANLIB=true
    fi

    FLAVOUR+=("LTO")
fi

if [ -n "$ENABLE_GPL" ]; then
    FLAVOUR+=("GPL")
fi

if [ -z "$ENABLE_CHECKS" ]; then
    CFLAGS+=" -fno-stack-protector -U_FORTIFY_SOURCE"
    CXXFLAGS+=" -fno-stack-protector -U_FORTIFY_SOURCE"
else
    CFLAGS+=" -fstack-protector -D_FORTIFY_SOURCE=2"
    CXXFLAGS+=" -fstack-protector -D_FORTIFY_SOURCE=2"

    if [ -n "$ENABLE_LTO" ]; then
        echo ""
        echo_warning "ENABLE_CHECKS=1 may not play well with ENABLE_LTO=1"
        sleep 2
    fi

    FLAVOUR+=("STACK PROTECTOR")
fi

export CC CXX CFLAGS CXXFLAGS CPPFLAGS LDFLAGS

if [ "${#FLAVOUR[@]}" -gt 0 ]; then
    FLAVOUR="$(implode ', ' FLAVOUR[@])"
else
    FLAVOUR="default"
fi

echo_action "setting build environment"
echo "$(echo_bold "CC") = $CC"
echo "$(echo_bold "CXX") = $CXX"
echo "$(echo_bold "NATIVE CC") = $CC_NATIVE"
echo "$(echo_bold "NATIVE CXX") = $CXX_NATIVE"
echo "$(echo_bold "AR") = $AR"
echo "$(echo_bold "RANLIB") = $RANLIB"
echo "$(echo_bold "LD") = $LD"
echo "$(echo_bold "CFLAGS") = $CFLAGS"
echo "$(echo_bold "CXXFLAGS") = $CXXFLAGS"
echo "$(echo_bold "LDFLAGS") = $LDFLAGS"
echo "$(echo_bold "TARGET") = $TARGET"
echo "$(echo_bold "FLAVOUR") = $FLAVOUR"
echo "$(echo_bold "JOBS") = $JOBS"

pushd $BUILD_DIR &>/dev/null
