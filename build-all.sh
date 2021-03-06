#!/bin/bash

. ./bash-tools.sh

# Always use CLEAN=1 for release builds as otherwise Apple's proprietary software
# will be packaged.
CLEAN=1
PREFIX=$1
if [[ -z $PREFIX ]] ; then
    error "Please pass in a PREFIX as argument 1, e.g. apple"
    error "If it contains debug or dbg, debugabble toolchains"
    error "are made."
    exit 1
fi

MAKING_DEBUG=no
case $PREFIX in
  *debug*)
    MAKING_DEBUG=yes
    ;;
  *dbg*)
    MAKING_DEBUG=yes
    ;;
  *)
    ;;
esac

UNAME=$(uname_bt)

BASE_TMP=/tmp2/tc4
# On MSYS, /tmp is in a deep folder (C:\Users\me\blah); deep folders and Windows
# don't get along, so /tmp2 is used instead.
if [[ "$(uname_bt)" == "Windows" ]] ; then
	BASE_TMP=/tmp2/tc4
fi

DEBIAN_VERSION=
if [ -f /etc/debian_version ] ; then
  DEBIAN_VERSION=$(head -n 1 /etc/debian_version)
fi

# $1 is path
# $2 is string to find
# $3 is string to replace with
# (always looks for .la files and any with ldscripts in the path.
rebase_absolute_paths ()
{
    local _PATH=$1
    local _FIND=$2
    local _REPL=$3

    FILES="$(find $_PATH \( -name '*.la' -or -path '*/ldscripts/*' -or -name '*.conf' -or -name 'mkheaders' -or -name '*.py' -or -name '*.h' \))"
    for FILE in $FILES; do
        sed -i "s#${_FIND}#${_REPL}#g" $FILE
    done
}

HOST_COMPILERS_ROOT_HOST=$PWD/sdks
if [ ! "$DEBIAN_VERSION" = "6.0.5" -a "$(uname_bt)" = "Linux" ] ; then
    BINPREFIX=i686-linux
    CC=$BINPREFIX-gcc
    CXX=$BINPREFIX-g++
    LD=$BINPREFIX-ld
    AS=$BINPREFIX-as
    AR=$BINPREFIX-ar
    RANLIB=$BINPREFIX-ranlib
    STRIP=$BINPREFIX-strip
    export CC CXX LD AS AR RANLIB STRIP

    # Get Google's glibc2.7 GCC 4.6 compilers; the same ones that are used to build the Android NDK.
    LINUX32_CC_URL=https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/host/i686-linux-glibc2.7-4.6
    LINUX64_CC_URL=https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.7-4.6
    if [ ! -d $HOST_COMPILERS_ROOT_HOST/$(basename $LINUX32_CC_URL) ]; then
        (
         [ -d $HOST_COMPILERS_ROOT_HOST ] || mkdir -p $HOST_COMPILERS_ROOT_HOST
         cd $HOST_COMPILERS_ROOT_HOST
         git clone $LINUX32_CC_URL $(basename $LINUX32_CC_URL)
         find . \( -name "*.la" -or -path "*ldscripts*" \)
        )
        rebase_absolute_paths "$HOST_COMPILERS_ROOT_HOST/$(basename $LINUX32_CC_URL)" "/tmp/ahsieh-gcc-32-x19222/2/i686-linux-glibc2.7-4.6" "$PWD/prebuilts/gcc/linux-x86/host/prebuilts-gcc-linux-x86-host-i686-linux-glibc2.7-4.6"
        # This is just to catch one file ;-)
        rebase_absolute_paths "$HOST_COMPILERS_ROOT_HOST/$(basename $LINUX32_CC_URL)" "/tmp/ahsieh-gcc-32-x19222/1/i686-linux-glibc2.7-4.6" "$PWD/prebuilts/gcc/linux-x86/host/prebuilts-gcc-linux-x86-host-i686-linux-glibc2.7-4.6"
    fi
    if [ ! -d $HOST_COMPILERS_ROOT_HOST/$(basename $LINUX64_CC_URL) ]; then
        (
        [ -d $HOST_COMPILERS_ROOT_HOST ] || mkdir -p $HOST_COMPILERS_ROOT_HOST
         cd $HOST_COMPILERS_ROOT_HOST
         git clone $LINUX64_CC_URL $(basename $LINUX64_CC_URL)
        )
        rebase_absolute_paths "$HOST_COMPILERS_ROOT_HOST/$(basename $LINUX64_CC_URL)" "/tmp/ahsieh-gcc-64-X27190/2"                         "$PWD/prebuilts/gcc/linux-x86/host"
    fi
    export PATH=$HOST_COMPILERS_ROOT_HOST/$(basename $LINUX32_CC_URL)/bin:$PATH
fi

DST=${BASE_TMP}/final-install

if [ $MAKING_DEBUG = yes ] ; then
   echo "*************************"
   echo "*** Making Debuggable ***"
   echo "*************************"
   export HOST_DEBUG_CFLAGS="-O0 -g"
fi

full_build_for_arch() {
    local _TARGET_ARCH=$2
    if [[ "$_TARGET_ARCH" = "arm" ]] ; then
        local _PREFIX_SUFFIX=$1-ios
    else
        local _PREFIX_SUFFIX=$1-osx
    fi
    rm -rf bld-$_PREFIX_SUFFIX src-$_PREFIX_SUFFIX $DST/$_PREFIX_SUFFIX
    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh llvmgcc-core $_TARGET_ARCH
    rm -rf bld-$1/cctools-809-${_TARGET_ARCH} src-$_PREFIX_SUFFIX/cctools-809
    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh cctools $_TARGET_ARCH
    rm -rf bld-$1/gcc-5666.3-${_TARGET_ARCH} src-$_PREFIX_SUFFIX/gcc-5666.3
    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh gcc $_TARGET_ARCH
    rm -rf bld-$_PREFIX_SUFFIX/llvmgcc42-2336.1-full-${_TARGET_ARCH} src-$_PREFIX_SUFFIX/llvmgcc42-2336.1
    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh llvmgcc $_TARGET_ARCH
    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh gccdriver $_TARGET_ARCH
}

# Clean everything.
ARM_BUILD=1
if [ "$ARM_BUILD" = "1" ] ; then
    # Make arm build.
    full_build_for_arch $PREFIX arm

    # Since I moved to mingw64, the libgcc_s*.dylib aren't being copied to the right place. In fact, I'm
    # not sure if it's the gcc or the llvmgcc install that's meant to write them. llvmgcc and gcc libgccs are
    # Probably best kept separate.
    if [[ "$UNAME" = "Windows" ]] ; then
        cp $DST/${PREFIX}-ios/arm-apple-darwin11/lib/libgcc_s* $DST/${PREFIX}-ios/lib/
    fi

    if [[ $CLEAN = 1 ]] ; then
        rm -rf $DST/${PREFIX}-ios/usr/lib
        rm -rf $DST/${PREFIX}-ios/arm-apple-darwin11/lib
        rm $DST/${PREFIX}-ios/lib/libSystem.B.dylib
        rm -rf $DST/${PREFIX}-ios/usr/include
        rm -rf $DST/${PREFIX}-ios/arm-apple-darwin11/sys-include
        rm -rf $DST/${PREFIX}-ios/arm-apple-darwin11
    fi
    # Since libstdc++ doesn't build, we need to get the headers from an existing SDK.
    if [ ! -d $DST/${PREFIX}-ios/include/c++ ] ; then
        mkdir -p $DST/${PREFIX}-ios/include/c++
    fi
    TOPDIR=$PWD
    pushd $DST/${PREFIX}-ios/include/c++
    cp -rf $TOPDIR/sdks/iPhoneOS4.3.sdk/usr/include/c++/4.2.1 4.2.1
    mv 4.2.1/arm-apple-darwin10 4.2.1/arm-apple-darwin11
    cp -rf 4.2.1/arm-apple-darwin11/v7/bits 4.2.1/arm-apple-darwin11/
    mv 4.2.1/armv6-apple-darwin10 4.2.1/armv6-apple-darwin11
    mv 4.2.1/armv7-apple-darwin10 4.2.1/armv7-apple-darwin11
    popd
fi
# Copy dlls (only one or other of libgcc_s_dw2-1.dll and libgcc_s_sjlj-1.dll needed)
if [[ "$UNAME" = "Windows" ]] ; then
    for _DLL in libintl-8.dll libiconv-2.dll libgcc_s_dw2-1.dll libgcc_s_sjlj-1.dll libwinpthread-1.dll libstdc++-6.dll pthreadGC2.dll
    do
        cp -rf /mingw/bin/$_DLL $DST/${PREFIX}-ios/bin
        cp -rf /mingw/bin/$_DLL $DST/${PREFIX}-ios/libexec/gcc/arm-apple-darwin11/4.2.1
        cp -rf /mingw/bin/$_DLL $DST/${PREFIX}-ios/libexec/llvmgcc/arm-apple-darwin11/4.2.1
    done
fi

INTEL_BUILD=1
if [ "$INTEL_BUILD" = "1" ] ; then
    # Make i686 build.
    full_build_for_arch $PREFIX intel

    # Since I moved to mingw64, the libgcc_s*.dylib aren't being copied to the right place. In fact, I'm
    # not sure if it's the gcc or the llvmgcc install that's meant to write them. llvmgcc and gcc libgccs are
    # Probably best kept separate.
    if [[ "$UNAME" = "Windows" ]] ; then
        cp $DST/${PREFIX}-osx/i686-apple-darwin11/lib/libgcc_s* $DST/${PREFIX}-osx/lib/
    fi

    if [[ $CLEAN = 1 ]] ; then
        rm -rf $DST/${PREFIX}-osx/usr/lib
        rm -rf $DST/${PREFIX}-osx/i686-apple-darwin11/lib
        rm $DST/${PREFIX}-osx/lib/libSystem.B.dylib
        rm -rf $DST/${PREFIX}-osx/usr/include
        rm -rf $DST/${PREFIX}-osx/i686-apple-darwin11/sys-include
        rm -rf $DST/${PREFIX}-osx/i686-apple-darwin11
    fi
    # Since libstdc++ doesn't build, we need to get the headers from an existing SDK.
    if [ ! -d $DST/${PREFIX}-osx/include/c++ ] ; then
        mkdir -p $DST/${PREFIX}-osx/include/c++
    fi
    TOPDIR=$PWD
    pushd $DST/${PREFIX}-osx/include/c++
    cp -rf $TOPDIR/sdks/MacOSX10.7.sdk/usr/include/c++/4.2.1 4.2.1
    popd
fi
# Copy dlls (only one or other of libgcc_s_dw2-1.dll and libgcc_s_sjlj-1.dll needed)
if [[ "$UNAME" = "Windows" ]] ; then
    for _DLL in libintl-8.dll libiconv-2.dll libgcc_s_dw2-1.dll libgcc_s_sjlj-1.dll libwinpthread-1.dll libstdc++-6.dll pthreadGC2.dll
    do
        cp -rf /mingw/bin/$_DLL $DST/${PREFIX}-osx/bin
        cp -rf /mingw/bin/$_DLL $DST/${PREFIX}-osx/libexec/gcc/i686-apple-darwin11/4.2.1
        cp -rf /mingw/bin/$_DLL $DST/${PREFIX}-osx/libexec/llvmgcc/i686-apple-darwin11/4.2.1
    done
fi

# For some reason, make install on Windows isn't copying the x86_64 folders so work around that.
if [[ ! -d $DST/${PREFIX}-osx/lib/llvmgcc42/i686-apple-darwin11/4.2.1/x86_64 ]] ; then
    cp -rf ${BASE_TMP}/bld-${PREFIX}-osx/llvmgcc42-2336.1-full-i686/gcc/x86_64 $DST/${PREFIX}-osx/lib/llvmgcc/i686-apple-darwin11/4.2.1/
fi
if [[ ! -d $DST/${PREFIX}-osx/lib/gcc/i686-apple-darwin11/4.2.1/x86_64 ]] ; then
    cp -rf ${BASE_TMP}/bld-${PREFIX}-osx/gcc-5666.3-i686/gcc/x86_64 $DST/${PREFIX}-osx/lib/gcc/i686-apple-darwin11/4.2.1/
fi

if [ $MAKING_DEBUG = no ] ; then
    # Strip executables.
    # Maybe "strip -u -r -S" when on OS X?
    if [[ ! "$UNAME" = "Darwin" ]] ; then
        find $DST/${PREFIX}-ios/bin -type f -and -not \( -path "*-config" -or -path "*-gccbug" \) | xargs strip
        find $DST/${PREFIX}-ios/libexec -type f -and -not \( -path "*.sh" -or -path "*mkheaders" \) | xargs strip
        find $DST/${PREFIX}-osx/bin -type f -and -not \( -path "*-config" -or -path "*-gccbug"  \) | xargs strip
        find $DST/${PREFIX}-osx/libexec -type f -and -not \( -path "*.sh" -or -path "*mkheaders" \) | xargs strip
    fi
fi

find $DST -type d -empty -exec rmdir {} \;

cp ${BASE_TMP}/src-${PREFIX}-osx/cctools-809/APPLE_LICENSE $DST/${PREFIX}-osx
chmod 0777 $DST/${PREFIX}-osx/APPLE_LICENSE
cp ${BASE_TMP}/src-${PREFIX}-osx/llvmgcc42-2336.1/COPYING $DST/${PREFIX}-osx
cp ${BASE_TMP}/src-${PREFIX}-osx/llvmgcc42-2336.1/llvmCore/LICENSE.TXT $DST/${PREFIX}-osx

cp ${BASE_TMP}/src-${PREFIX}-osx/cctools-809/APPLE_LICENSE $DST/${PREFIX}-ios
chmod 0777 $DST/${PREFIX}-ios/APPLE_LICENSE
cp ${BASE_TMP}/src-${PREFIX}-osx/llvmgcc42-2336.1/COPYING $DST/${PREFIX}-ios
cp ${BASE_TMP}/src-${PREFIX}-osx/llvmgcc42-2336.1/llvmCore/LICENSE.TXT $DST/${PREFIX}-ios

DATESUFFIX=$(date +%y%m%d)
if [ $MAKING_DEBUG = yes ] ; then
    OUTFILEPREFIX=$PWD/multiarch-darwin11-cctools127.2-gcc42-5666.3-llvmgcc42-2336.1-$UNAME-dbg-${DATESUFFIX}.hackin2
else
    OUTFILEPREFIX=$PWD/multiarch-darwin11-cctools127.2-gcc42-5666.3-llvmgcc42-2336.1-$UNAME-${DATESUFFIX}.hackin2
fi
OUTFILE=$(compress_folders "$DST/." $OUTFILEPREFIX)
cp $OUTFILE ~/Dropbox/darwin-compilers-work
