#!/bin/bash

# References. This work stands on the work done in these projects.
# Some people who provide ports of debian packages for MinGW!
# http://svn.clazzes.org/svn/mingw-pkg/trunk/macosx-deb/macosx-intel64-cctools/patches/cctools-806-nondarwin.patch  <--  with Windows fixes.
# Their home page:
# https://www.clazzes.org/projects/mingw-debian-packaging/
# Andrew's toolchain:
# https://github.com/tatsh/xchain
# Chromium uses this I think:
# http://code.google.com/p/toolwhip/
# Javacom:
# https://github.com/javacom/toolchain4
# One of the originals:
# http://code.google.com/p/iphonedevonlinux/

# TODORMD :: with_prefix.diff needs fixing to be relocatable (/usr/bin/objcunique is completely wrong too)

set -e

. ../bash-tools.sh

CCTOOLSNAME=cctools
CCTOOLSVERS=809
LD64NAME=ld64
LD64VERS=127.2
LD64DISTFILE=${LD64NAME}-${LD64VERS}.tar.gz
# For dyld.h.
DYLDNAME=dyld
DYLDVERS=195.5
DYLDDISTFILE=${DYLDNAME}-${DYLDVERS}.tar.gz

OSXVER=10.7

TOPSRCDIR=`pwd`

MAKEDISTFILE=0
UPDATEPATCH=0
# To use MacOSX headers set USESDK to 999.
#USESDK=999
USESDK=1
FOREIGNHEADERS=

while [ $# -gt 0 ]; do
    case $1 in
	--distfile)
	    shift
	    MAKEDISTFILE=1
	    ;;
	--updatepatch)
	    shift
	    UPDATEPATCH=1
	    ;;
	--nosdk)
	    shift
	    USESDK=0
	    ;;
	--help)
	    echo "Usage: $0 [--help] [--distfile] [--updatepatch] [--nosdk]" 1>&2
	    exit 0
	    ;;
	--vers)
	    shift
	    CCTOOLSVERS=$1
	    shift
	    ;;
	--foreignheaders)
	    shift
	    FOREIGNHEADERS=-foreign-headers
	    ;;
	--osxver)
	    shift
	    OSXVER=$1
	    shift
	    ;;
	*)
	    echo "Unknown option $1" 1>&2
	    exit 1
    esac
done

CCTOOLSDISTFILE=${CCTOOLSNAME}-${CCTOOLSVERS}.tar.gz
DISTDIR=odcctools-${CCTOOLSVERS}${FOREIGNHEADERS}

USE_OSX_MACHINE_H=0
if [[ -z $FOREIGNHEADERS ]] ; then
    USE_OSX_MACHINE_H=1
fi

if [ "`tar --help | grep -- --strip-components 2> /dev/null`" ]; then
    TARSTRIP=--strip-components
elif [ "`tar --help | grep bsdtar 2> /dev/null`" ]; then
    TARSTRIP=--strip-components
else
    TARSTRIP=--strip-path
fi

PATCHFILESDIR=${TOPSRCDIR}/patches-${CCTOOLSVERS}

#PATCHFILES=`cd "${PATCHFILESDIR}" && find * -type f \! -path \*/.svn\* | sort`

if [[ ! "$(uname -s)" = "Darwin" ]] ; then
    LD64_CREATE_READER_TYPENAME_DIFF=ld64/ld_createReader_typename.diff
fi

if [[ "$LD64VERS" == "85.2.1" ]] ; then
    LD64PATCHES="ld64/FileAbstraction-inline.diff ld64/ld_cpp_signal.diff \
ld64/Options-config_h.diff ld64/Options-ctype.diff \
ld64/Options-defcross.diff ld64/Options_h_includes.diff \
ld64/Options-stdarg.diff ld64/remove_tmp_math_hack.diff \
ld64/Thread64_MachOWriterExecutable.diff ${LD64_CREATE_READER_TYPENAME_DIFF} \
ld64/ld_BaseAtom_def_fix.diff ld64/LTOReader-setasmpath.diff \
ld64/cstdio.diff"
else
    LD64PATCHES="ld64/QSORT_macho_relocatable_file.diff"
fi

# Removed as/getc_unlocked.diff as all it did was re-include config.h
# Removed libstuff/cmd_with_prefix.diff as it's wrong.

if [[ "$USE_OSX_MACHINE_H" = "0" ]] ; then
PATCHFILES="ar/archive.diff ar/ar-printf.diff ar/ar-ranlibpath.diff \
ar/contents.diff ar/declare_localtime.diff ar/errno.diff as/arm.c.diff \
as/bignum.diff as/input-scrub.diff as/driver.c.diff \
as/messages.diff as/relax.diff as/use_PRI_macros.diff \
include/mach/machine.diff include/stuff/bytesex-floatstate.diff \
${LD64PATCHES} \
ld-sysroot.diff ld/uuid-nonsmodule.diff libstuff/default_arch.diff \
libstuff/macosx_deployment_target_default_105.diff \
libstuff/map_64bit_arches.diff libstuff/sys_types.diff \
libstuff/mingw_execute.diff libstuff/realpath_execute.diff libstuff/ofile_map_unmap_mingw.diff \
misc/libtool-ldpath.diff misc/libtool_lipo_transform.diff \
misc/ranlibname.diff misc/redo_prebinding.nogetattrlist.diff \
misc/redo_prebinding.nomalloc.diff \
otool/nolibmstub.diff otool/noobjc.diff otool/dontTypedefNXConstantString.diff \
include/mach/machine_armv7.diff \
ld/ld-nomach.diff \
misc/bootstrap_h.diff"
else
# Removed as/driver.c.diff as we've got _NSGetExecutablePath.
PATCHFILES="ar/archive.diff ar/ar-printf.diff ar/ar-ranlibpath.diff \
ar/contents.diff ar/declare_localtime.diff ar/errno.diff as/arm.c.diff \
as/bignum.diff as/input-scrub.diff as/driver.c.diff \
as/messages.diff as/relax.diff \
include/stuff/bytesex-floatstate.diff \
${LD64PATCHES} \
ld-sysroot.diff ld/uuid-nonsmodule.diff libstuff/default_arch.diff \
libstuff/macosx_deployment_target_default_105.diff \
libstuff/map_64bit_arches.diff libstuff/sys_types.diff \
libstuff/mingw_execute.diff libstuff/realpath_execute.diff libstuff/ofile_map_unmap_mingw.diff \
misc/libtool-ldpath.diff misc/libtool_lipo_transform.diff \
misc/ranlibname.diff misc/redo_prebinding.nogetattrlist.diff \
misc/redo_prebinding.nomalloc.diff \
otool/nolibmstub.diff otool/noobjc.diff otool/dontTypedefNXConstantString.diff \
include/mach/machine_armv7.diff \
ld/ld-nomach.diff \
misc/bootstrap_h.diff"
fi

ADDEDFILESDIR=${TOPSRCDIR}/files

# My BootstrapMinGW64.vbs doesn't install install.exe if the user selects msysgit...
# Urgh. Really, the vbs script should launch bash with a command line to finish the job.
if [ ! $(which install) ] ; then
    if [[ "$(uname_bt)" = "Windows" ]] ; then
        download http://garr.dl.sourceforge.net/project/mingw/MSYS/Base/coreutils/coreutils-5.97-3/coreutils-5.97-3-msys-1.0.13-bin.tar.lzma
        tar ${TARSTRIP}=0 -xJf coreutils-5.97-3-msys-1.0.13-bin.tar.lzma -C /tmp > /dev/null 2>&1
        cp /tmp/bin/install.exe /bin/
    fi
fi

if [[ ! "$(uname_bt)" = "Windows" ]] ; then
    PATCH_POSIX=--posix
fi

if [ -d "${DISTDIR}" ]; then
    echo "${DISTDIR} already exists. Please move aside before running" 1>&2
    exit 1
fi

rm -rf ${DISTDIR}
mkdir -p ${DISTDIR}
[[ ! -f "${CCTOOLSDISTFILE}" ]] && download http://www.opensource.apple.com/tarballs/cctools/${CCTOOLSDISTFILE}
if [[ ! -f "${CCTOOLSDISTFILE}" ]] ; then
    error "Failed to download ${CCTOOLSDISTFILE}"
    exit 1
fi
tar ${TARSTRIP}=1 -xf ${CCTOOLSDISTFILE} -C ${DISTDIR} > /dev/null 2>&1
# Fix dodgy timestamps.
find ${DISTDIR} | xargs touch

[[ ! -f "${LD64DISTFILE}" ]] && download http://www.opensource.apple.com/tarballs/ld64/${LD64DISTFILE}
if [[ ! -f "${LD64DISTFILE}" ]] ; then
    error "Failed to download ${LD64DISTFILE}"
    exit 1
fi
mkdir -p ${DISTDIR}/ld64
tar ${TARSTRIP}=1 -xf ${LD64DISTFILE} -C ${DISTDIR}/ld64 > /dev/null 2>&1
rm -rf ${DISTDIR}/ld64/FireOpal
find ${DISTDIR}/ld64 ! -perm +200 -exec chmod u+w {} \;
find ${DISTDIR}/ld64/doc/ -type f -exec cp "{}" ${DISTDIR}/man \;

[[ ! -f "${DYLDDISTFILE}" ]] && download http://www.opensource.apple.com/tarballs/dyld/${DYLDDISTFILE}
if [[ ! -f "${DYLDDISTFILE}" ]] ; then
    error "Failed to download ${DYLDDISTFILE}"
    exit 1
fi
mkdir -p ${DISTDIR}/dyld
tar ${TARSTRIP}=1 -xf ${DYLDDISTFILE} -C ${DISTDIR}/dyld

mkdir ${DISTDIR}/libprunetrie
mkdir ${DISTDIR}/libprunetrie/mach-o
cp ${DISTDIR}/ld64/src/other/prune_trie.h ${DISTDIR}/libprunetrie/
cp ${DISTDIR}/ld64/src/other/prune_trie.h ${DISTDIR}/libprunetrie/mach-o/
cp ${DISTDIR}/ld64/src/other/PruneTrie.cpp ${DISTDIR}/libprunetrie/

# Clean the source a bit
find ${DISTDIR} -name \*.orig -exec rm -f "{}" \;
rm -rf ${DISTDIR}/{cbtlibs,file,gprof,libdyld,mkshlib,profileServer}

if [[ "$(uname -s)" = "Darwin" ]] ; then
    SDKROOT=/Developer/SDKs/MacOSX${OSXVER}.sdk
    if [[ ! -d $SDKROOT ]] ; then
    # Sandboxing... OSX becomes more like iOS every day.
    SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX${OSXVER}.sdk
    fi
else
    SDKROOT=$(cd ${TOPSRCDIR}/../sdks/MacOSX${OSXVER}.sdk && pwd)
fi
cp -Rf ${SDKROOT}/usr/include/objc ${DISTDIR}/include

# llvm headers
# Originally, in toolchain4, gcc used was Saurik's, but that doesn't contain
# the llvm-c headers we need.
message_status "Merging include/llvm-c from Apple's llvmgcc42-2336.1"
GCC_DIR=${TOPSRCDIR}/../llvmgcc42-2336.1
if [ ! -d $GCC_DIR ]; then
    pushd $(dirname ${GCC_DIR})
    if [[ $(download http://www.opensource.apple.com/tarballs/llvmgcc42/llvmgcc42-2336.1.tar.gz) ]] ; then
        error "Failed to download llvmgcc42-2336.1.tar.gz"
        exit 1
    fi
    tar -zxf llvmgcc42-2336.1.tar.gz
    popd
fi
cp -rf ${GCC_DIR}/llvmCore/include/llvm-c ${DISTDIR}/include/

if [[ $USESDK -eq 999 ]] || [[ ! "$FOREIGNHEADERS" = "-foreign-headers" ]]; then
    message_status "Merging content from ${SDKROOT} to ${DISTDIR}"
    if [ ! -d "$SDKROOT" ]; then
    error "$SDKROOT must be present"
    exit 1
    fi

    mv ${DISTDIR}/include/mach/machine.h ${DISTDIR}/include/mach/machine.h.new
    if [[ "$(uname_bt)" = "Darwin" ]] ; then
        SYSFLDR=sys
    else
        # Want to use the system's sys folder as much as possible.
        SYSFLDR=sys/_types.h
    fi
    for i in mach architecture i386 libkern $SYSFLDR; do
    tar cf - -C "$SDKROOT/usr/include" $i | tar xf - -C ${DISTDIR}/include
    done

    if [[ "$USE_OSX_MACHINE_H" = "1" ]] ; then
    mv ${DISTDIR}/include/mach/machine.h.new ${DISTDIR}/include/mach/machine.h
    fi

#   Although this does what it's supposed to, it's not what's needed; Linux version isn't seen until later.
#   comment_out_rev ${DISTDIR}/include/i386/_types.h "typedef union {" "} __mbstate_t;"
    do_sed $"s/} __mbstate_t/} NONCONFLICTING__mbstate_t/" ${DISTDIR}/include/i386/_types.h
    do_sed $"s/typedef __mbstate_t/typedef NONCONFLICTING__mbstate_t/" ${DISTDIR}/include/i386/_types.h


#    rm ${DISTDIR}/include/sys/cdefs.h
#    rm ${DISTDIR}/include/sys/types.h
#    rm ${DISTDIR}/include/sys/select.h

# If this is enabled, libkern/machine/OSByteOrder.h is used instead of
# libkern/i386/OSByteOrder.h and this causes failure on Darwin, it may
# be needed on other OSes though?
#    for f in ${DISTDIR}/include/libkern/OSByteOrder.h; do
#	sed -e 's/__GNUC__/__GNUC_UNUSED__/g' < $f > $f.tmp
#	mv -f $f.tmp $f
#    done
fi

# process source for mechanical substitutions
message_status "Removing #import"
find ${DISTDIR} -type f -name \*.[ch] | while read f; do
    sed -e 's/^#import/#include/' < $f > $f.tmp
    mv -f $f.tmp $f
done

message_status "Removing __private_extern__"
find ${DISTDIR} -type f -name \*.h | while read f; do
    sed -e 's/^__private_extern__/extern/' < $f > $f.tmp
    mv -f $f.tmp $f
done

#echo "Removing static enum bool"
#find ${DISTDIR} -type f -name \*.[ch] | while read f; do
#    sed -e 's/static enum bool/static bool/' < $f > $f.tmp
#    mv -f $f.tmp $f
#done

set +e

INTERACTIVE=0
message_status "Applying patches"
for p in ${PATCHFILES}; do
    dir=`dirname $p`
    if [ $INTERACTIVE -eq 1 ]; then
	read -p "Apply patch $p? " REPLY
    else
	message_status "Applying patch $p"
    fi
    pushd ${DISTDIR}/$dir > /dev/null
    patch $PATCH_POSIX -p0 < ${PATCHFILESDIR}/$p
    if [ $? -ne 0 ]; then
        error "There was a patch failure. Please manually merge and exit the sub-shell when done"
        $SHELL
        if [ $UPDATEPATCH -eq 1 ]; then
            find . -type f | while read f; do
            if [ -f "$f.orig" ]; then
                diff -u -N "$f.orig" "$f"
            fi
            done > ${PATCHFILESDIR}/$p
        fi
    fi
    # For subsequent patches to work, move orig files out of the way
    # to a filename that includes the patch name, e.g. archive.c.orig.archive.diff
    find . -type f -name \*.orig -exec mv "{}" "{}"$(basename $p) \;
    popd > /dev/null
done

set -e

message_status "Adding new files to $DISTDIR"

if [[ "$(uname_bt)" = "Windows" ]] ; then
    # Make sys/cdefs.h
    mkdir -p ${DISTDIR}/include/sys/
    echo "#ifndef __SYS_CDEFS_H_" > ${DISTDIR}/include/sys/cdefs.h
    echo "#define __SYS_CDEFS_H_" >> ${DISTDIR}/include/sys/cdefs.h
    echo "#ifdef __cplusplus" >> ${DISTDIR}/include/sys/cdefs.h
    echo "#define __BEGIN_DECLS extern \"C\" {" >> ${DISTDIR}/include/sys/cdefs.h
    echo "#define __END_DECLS }" >> ${DISTDIR}/include/sys/cdefs.h
    echo "#else" >> ${DISTDIR}/include/sys/cdefs.h
    echo "#define __BEGIN_DECLS" >> ${DISTDIR}/include/sys/cdefs.h
    echo "#define __END_DECLS" >> ${DISTDIR}/include/sys/cdefs.h
    echo "#endif" >> ${DISTDIR}/include/sys/cdefs.h
    echo "#define	__P(protos) protos" >> ${DISTDIR}/include/sys/cdefs.h
#    echo "#define uid_t int32_t" >> ${DISTDIR}/include/sys/cdefs.h
#    echo "#define gid_t int32_t" >> ${DISTDIR}/include/sys/cdefs.h
#    echo "#define sigset_t int32_t" >> ${DISTDIR}/include/sys/cdefs.h
    echo -e "#endif\n" >> ${DISTDIR}/include/sys/cdefs.h

    echo "#ifndef __SYS_ENDIAN_H_" > ${DISTDIR}/include/sys/_endian.h
    echo "#define HTONS(_h) (((((uint16_t)(_h) & 0xff)) << 8)  | (((uint16_t)(_h) & 0xff00) >> 8))" >> ${DISTDIR}/include/sys/_endian.h
    echo "#define NTOHS(_n) (((((uint16_t)(_n) & 0xff)) << 8)  | (((uint16_t)(_n) & 0xff00) >> 8))" >> ${DISTDIR}/include/sys/_endian.h
    echo "#define HTONL(_h) (((((uint32_t)(_h) & 0xff)) << 24) | ((((uint32_t)(_h) & 0xff00)) << 8) | ((((uint32_t)(_h) & 0xff0000)) >> 8) | ((((uint32_t)(_h) & 0xff000000)) >> 24))" >> ${DISTDIR}/include/sys/_endian.h
    echo "#define NTOHL(_h) (((((uint32_t)(_n) & 0xff)) << 24) | ((((uint32_t)(_n) & 0xff00)) << 8) | ((((uint32_t)(_n) & 0xff0000)) >> 8) | ((((uint32_t)(_n) & 0xff000000)) >> 24))" >> ${DISTDIR}/include/sys/_endian.h
    echo "#define htons(_h) HTONS(_h)" >> ${DISTDIR}/include/sys/_endian.h
    echo "#define ntohs(_n) NTOHS(_n)" >> ${DISTDIR}/include/sys/_endian.h
    echo "#define htonl(_h) HTONL(_h)" >> ${DISTDIR}/include/sys/_endian.h
    echo "#define ntohl(_n) NTOHL(_n)" >> ${DISTDIR}/include/sys/_endian.h
    echo -e "#endif\n" >> ${DISTDIR}/include/sys/_endian.h

    echo "#ifndef _ERR_H_" >> ${DISTDIR}/include/err.h
    echo "#define _ERR_H_" >> ${DISTDIR}/include/err.h
    echo "#include <stdlib.h>" >> ${DISTDIR}/include/err.h
    echo "#define warn(...) do { \\" >> ${DISTDIR}/include/err.h
    echo "        fprintf (stderr, __VA_ARGS__); \\" >> ${DISTDIR}/include/err.h
    echo -e "        fprintf (stderr, \"\\\n\"); \\" >> ${DISTDIR}/include/err.h
    echo "} while (0)" >> ${DISTDIR}/include/err.h
    echo "#define warnx(...) do { \\" >> ${DISTDIR}/include/err.h
    echo "        fprintf (stderr, __VA_ARGS__); \\" >> ${DISTDIR}/include/err.h
    echo -e "        fprintf (stderr, \"\\\n\"); \\" >> ${DISTDIR}/include/err.h
    echo "} while (0)" >> ${DISTDIR}/include/err.h
    echo "#define err(code, ...) do { \\" >> ${DISTDIR}/include/err.h
    echo "        fprintf (stderr, __VA_ARGS__); \\" >> ${DISTDIR}/include/err.h
    echo -e "        fprintf (stderr, \"\\\n\"); \\" >> ${DISTDIR}/include/err.h
    echo "        exit (code); \\" >> ${DISTDIR}/include/err.h
    echo "} while (0)" >> ${DISTDIR}/include/err.h
    echo "#define errx(code, ...) do { \\" >> ${DISTDIR}/include/err.h
    echo "        fprintf (stderr, __VA_ARGS__); \\" >> ${DISTDIR}/include/err.h
    echo -e "        fprintf (stderr, \"\\\n\"); \\" >> ${DISTDIR}/include/err.h
    echo "        exit (code); \\" >> ${DISTDIR}/include/err.h
    echo "} while (0)" >> ${DISTDIR}/include/err.h
    echo -e "#endif\n" >> ${DISTDIR}/include/err.h
fi

tar cf - --exclude=CVS --exclude=.svn -C ${ADDEDFILESDIR} . | tar xvf - -C ${DISTDIR}
mv ${DISTDIR}/ld64/Makefile.in.${LD64VERS} ${DISTDIR}/ld64/Makefile.in
if [[ "${LD64VERS}" == "127.2" ]] ; then
    echo -e "\n" > ${DISTDIR}/ld64/src/ld/configure.h
fi

if [[ $USESDK -eq 999 ]] || [[ ! "$FOREIGNHEADERS" = "-foreign-headers" ]] ; then
    if [[ $(uname_bt) = "Darwin" ]] ; then
        cp -f ${SDKROOT}/usr/include/sys/cdefs.h ${DISTDIR}/include/sys/cdefs.h
        cp -f ${SDKROOT}/usr/include/sys/types.h ${DISTDIR}/include/sys/types.h
        cp -f ${SDKROOT}/usr/include/sys/select.h ${DISTDIR}/include/sys/select.h
        # causes arch.c failures (error: ?CPU_TYPE_VEO? undeclared here (not in a function)
        # cp -f ${SDKROOT}/usr/include/mach/machine.h ${DISTDIR}/include/mach/machine.h
    fi
fi

mkdir -p ${DISTDIR}/ld64/include/mach-o/
mkdir -p ${DISTDIR}/ld64/include/mach/
mkdir -p ${DISTDIR}/include/mach-o/
cp -f ${DISTDIR}/dyld/include/mach-o/dyld* ${DISTDIR}/ld64/include/mach-o/
cp -f ${SDKROOT}/usr/include/mach/machine.h ${DISTDIR}/ld64/include/mach/machine.h
cp -f ${SDKROOT}/usr/include/TargetConditionals.h ${DISTDIR}/include/TargetConditionals.h
cp -f ${SDKROOT}/usr/include/ar.h ${DISTDIR}/include/ar.h

do_sed $"s^#if defined(__GNUC__) && ( defined(__APPLE_CPP__) || defined(__APPLE_CC__) || defined(__MACOS_CLASSIC__) )^#if defined(__GNUC__)^" ${DISTDIR}/include/TargetConditionals.h

mkdir -p ${DISTDIR}/libprunetrie/include/mach-o
cp -f ${SDKROOT}/usr/include/mach-o/compact_unwind_encoding.h ${DISTDIR}/libprunetrie/include/mach-o/
cp -f ${SDKROOT}/usr/include/mach-o/compact_unwind_encoding.h ${DISTDIR}/include/mach-o/

# I had been localising stuff into ld64 (above), but a lot of it is
# more generally needed?
mkdir -p ${DISTDIR}/include/machine
mkdir -p ${DISTDIR}/include/mach_debug
mkdir -p ${DISTDIR}/include/CommonCrypto
cp -f ${SDKROOT}/usr/include/machine/types.h ${DISTDIR}/include/machine/types.h
cp -f ${SDKROOT}/usr/include/machine/_types.h ${DISTDIR}/include/machine/_types.h
cp -f ${SDKROOT}/usr/include/machine/endian.h ${DISTDIR}/include/machine/endian.h
cp -f ${SDKROOT}/usr/include/mach_debug/mach_debug_types.h ${DISTDIR}/include/mach_debug/mach_debug_types.h
cp -f ${SDKROOT}/usr/include/mach_debug/ipc_info.h ${DISTDIR}/include/mach_debug/ipc_info.h
cp -f ${SDKROOT}/usr/include/mach_debug/vm_info.h ${DISTDIR}/include/mach_debug/vm_info.h
cp -f ${SDKROOT}/usr/include/mach_debug/zone_info.h ${DISTDIR}/include/mach_debug/zone_info.h
cp -f ${SDKROOT}/usr/include/mach_debug/page_info.h ${DISTDIR}/include/mach_debug/page_info.h
cp -f ${SDKROOT}/usr/include/mach_debug/hash_info.h ${DISTDIR}/include/mach_debug/hash_info.h
cp -f ${SDKROOT}/usr/include/mach_debug/lockgroup_info.h ${DISTDIR}/include/mach_debug/lockgroup_info.h
cp -f ${SDKROOT}/usr/include/Availability.h ${DISTDIR}/include/Availability.h
cp -f ${SDKROOT}/usr/include/AvailabilityInternal.h ${DISTDIR}/include/AvailabilityInternal.h
cp -f ${SDKROOT}/usr/include/CommonCrypto/CommonDigest.h ${DISTDIR}/include/CommonCrypto/CommonDigest.h
cp -f ${SDKROOT}/usr/include/libunwind.h ${DISTDIR}/include/libunwind.h
cp -f ${SDKROOT}/usr/include/AvailabilityMacros.h ${DISTDIR}/include/AvailabilityMacros.h
if [[ "$(uname_bt)" = "Windows" ]] ; then
    echo "#ifndef _DLFCN_H_" > ${DISTDIR}/include/dlfcn.h
    echo "#define _DLFCN_H_" >> ${DISTDIR}/include/dlfcn.h
    echo "#ifdef __cplusplus" >> ${DISTDIR}/include/dlfcn.h
    echo "extern \"C\"" >> ${DISTDIR}/include/dlfcn.h
    echo "{" >> ${DISTDIR}/include/dlfcn.h
    echo "#endif" >> ${DISTDIR}/include/dlfcn.h
    echo "typedef struct" >> ${DISTDIR}/include/dlfcn.h
    echo "{" >> ${DISTDIR}/include/dlfcn.h
    echo "const char *dli_fname;" >> ${DISTDIR}/include/dlfcn.h
    echo "void *dli_fbase;" >> ${DISTDIR}/include/dlfcn.h
    echo "const char *dli_sname;" >> ${DISTDIR}/include/dlfcn.h
    echo "void *dli_saddr;" >> ${DISTDIR}/include/dlfcn.h
    echo "} Dl_info;" >> ${DISTDIR}/include/dlfcn.h
    echo "#define RTLD_LAZY 0" >> ${DISTDIR}/include/dlfcn.h
    echo "#define RTLD_NOW 1" >> ${DISTDIR}/include/dlfcn.h
    echo "typedef Dl_info dyldInfo;" >> ${DISTDIR}/include/dlfcn.h
    echo "typedef Dl_info dl_info;" >> ${DISTDIR}/include/dlfcn.h
    echo "#ifdef __cplusplus" >> ${DISTDIR}/include/dlfcn.h
    echo "}" >> ${DISTDIR}/include/dlfcn.h
    echo "#endif" >> ${DISTDIR}/include/dlfcn.h
    echo -e "#endif\n" >> ${DISTDIR}/include/dlfcn.h
else
    cp -f ${SDKROOT}/usr/include/dlfcn.h ${DISTDIR}/include/dlfcn.h
    do_sed $"s^#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)^//#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)^" ${DISTDIR}/include/dlfcn.h
    do_sed $"s%#endif /\* not POSIX \*/%//#endif /\* not POSIX \*/%" ${DISTDIR}/include/dlfcn.h
fi

#cp -f ${DISTDIR}/dyld/src/ImageLoader.h ${DISTDIR}/ld64/include/ImageLoader.h
#cp -f ${DISTDIR}/dyld/src/CrashReporterClient.h ${DISTDIR}/ld64/include/CrashReporterClient.h

if [ -z $FOREIGNHEADERS ] ; then
    message_status "Removing include/foreign"
    rm -rf ${DISTDIR}/include/foreign
else
    message_status "Removing include/mach/ppc (so include/foreign/mach/ppc is used)"
    rm -rf ${DISTDIR}/include/mach/ppc
fi

# ppc64 is disabled on non-darwin native builds, so let's re-enable it -> shouldn't break darwin native.
do_sed $"s^#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)^//#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)^" ${DISTDIR}/include/mach/ppc/thread_status.h
do_sed $"s%#endif /\* (_POSIX_C_SOURCE && !_DARWIN_C_SOURCE)%//#endif /\* _POSIX_C_SOURCE && !_DARWIN_C_SOURCE%" ${DISTDIR}/include/mach/ppc/thread_status.h

do_sed $"s^#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)^//#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)^" ${DISTDIR}/include/mach/ppc/_structs.h
do_sed $"s%#endif /\* (_POSIX_C_SOURCE && !_DARWIN_C_SOURCE)%//#endif /\* _POSIX_C_SOURCE && !_DARWIN_C_SOURCE%" ${DISTDIR}/include/mach/ppc/_structs.h

#libstuff
# Darwin has libc.h, Windows/Linux have a combination of stdio.h, stdlib.h, fcntl.h, unistd.h, io.h, sys/param.h (MAXPATHLEN)
do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <sys/param.h>\n#endif^" ${DISTDIR}/libstuff/execute.c
do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <fcntl.h>\n#include <sys/param.h>\n#endif^" ${DISTDIR}/libstuff/dylib_table.c

do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#endif^" ${DISTDIR}/libstuff/ofile.c
do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#endif^" ${DISTDIR}/libstuff/seg_addr_table.c
do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <fcntl.h>\n#include <sys/param.h>\n#endif^" ${DISTDIR}/libstuff/dylib_table.c
do_sed $"s^#include <sys/mman.h>^#ifndef __MINGW32__\n#include <sys/stat.h>\n#include <stdlib.h>\n#include <unistd.h>\n#include <sys/mman.h>\n#else\n#include <stdlib.h>\n#endif^" ${DISTDIR}/libstuff/ofile.c

if [[ "$(uname_bt)" = "Windows" ]] ; then
    do_sed $"s^#include <sys/mman.h>^#ifndef __MINGW32__\n#include <sys/mman.h>\n#endif^" ${DISTDIR}/libstuff/seg_addr_table.c
    do_sed $"s^#include <sys/mman.h>^#ifndef __MINGW32__\n#include <sys/mman.h>\n#endif^" ${DISTDIR}/libstuff/dylib_table.c
    do_sed $"s^u_char^uint8_t^" ${DISTDIR}/libstuff/crc32.c
    do_sed $"s^u_int32_t^uint32_t^" ${DISTDIR}/libstuff/crc32.c
    do_sed $"s^#include <sys/sysctl.h>^#ifdef __APPLE__\n#include <sys/sysctl.h>\n#endif^" ${DISTDIR}/libstuff/macosx_deployment_target.c

    do_sed $"s^osversion_name\[0\] = CTL_KERN;^osversion_name\[0\] = 11;^" ${DISTDIR}/libstuff/macosx_deployment_target.c
    do_sed $"s^osversion_name\[1\] = KERN_OSRELEASE;^osversion_name\[1\] = 0;^" ${DISTDIR}/libstuff/macosx_deployment_target.c
    do_sed $"s^if(sysctl(osversion_name, 2, osversion, &osversion_len, NULL, 0) == -1)^strcpy(osversion,\"11.0\");^" ${DISTDIR}/libstuff/macosx_deployment_target.c
    do_sed $"s^system_error(\"sysctl for kern.osversion failed\");^^" ${DISTDIR}/libstuff/macosx_deployment_target.c
fi

if [[ "$(uname_bt)" = "Linux" ]] || [[ "$(uname_bt)" = "Darwin" ]] ; then
    do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/stat.h>\n#include <time.h>\n#include <sys/param.h>\n#include <unistd.h>\n#endif^" ${DISTDIR}/libstuff/writeout.c
elif [[ "$(uname_bt)" = "Windows" ]] ; then
    do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <io.h>\n#endif^" ${DISTDIR}/libstuff/writeout.c
fi
do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <sys/param.h>\n#endif^" ${DISTDIR}/libstuff/SymLoc.c
do_sed $"s^#include <sys/sysctl.h>^#include <stdint.h>\n#include <sys/sysctl.h>^" ${DISTDIR}/libstuff/macosx_deployment_target.c
do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <fcntl.h>\n#include <sys/param.h>\n#include <string.h>\n#endif^" ${DISTDIR}/libstuff/lto.c

do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <fcntl.h>\n#include <sys/param.h>\n#include <stdint.h>\n#include <string.h>\n#endif^" ${DISTDIR}/libstuff/llvm.c
#do_sed $"s^#include <dlfcn.h>^#ifndef __MINGW32__\n#include <dlfcn.h>\n#endif^" ${DISTDIR}/libstuff/llvm.c

# ar
do_sed $"s^__unused^__attribute__((__unused__))^" ${DISTDIR}/include/mach/mig_errors.h
do_sed $"s^__unused^__attribute__((__unused__))^" ${DISTDIR}/include/objc/objc-auto.h
do_sed $"s^#include <sys/stat.h>^#include <sys/stat.h>\n#ifndef __APPLE__\n#include <sys/file.h>\n#define AR_EFMT1 \"#1/\"\n#endif^" ${DISTDIR}/ar/archive.c
do_sed $"s^#include <paths.h>^#ifndef __MINGW32__\n#include <paths.h>\n#endif^" ${DISTDIR}/ar/ar.c
do_sed $"s^#include <unistd.h>^#include <unistd.h>\n#include <stdint.h>\n^" ${DISTDIR}/ar/contents.c

# as
do_sed $"s^#include \"libc.h\"^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <sys/file.h>\n#include <sys/param.h>\n#endif^" ${DISTDIR}/as/driver.c
do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#endif^" ${DISTDIR}/as/input-file.c
do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#endif^" ${DISTDIR}/as/input-scrub.c
do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <sys/stat.h>#endif\n#endif^" ${DISTDIR}/as/write_object.c
if [[ "$(uname_bt)" = "Windows" ]] ; then
    do_sed $"s^if(realpath == NULL)^if(prefix == NULL)^" ${DISTDIR}/as/driver.c
    # Windows doesn't have SIGHUP or SIGPIPE...
    do_sed $"s^static int sig\[\] = { SIGHUP, SIGINT, SIGPIPE, SIGTERM, 0};^#ifdef __MINGW32__\nstatic int sig\[\] = { SIGINT, SIGTERM, 0};\n#else\nstatic int sig\[\] = { SIGHUP, SIGINT, SIGPIPE, SIGTERM, 0};\n#endif^" ${DISTDIR}/as/as.c
    do_sed $"s^static int sig\[\] = { SIGHUP, SIGINT, SIGPIPE, SIGTERM, 0};^#ifdef __MINGW32__\nstatic int sig\[\] = { SIGINT, SIGTERM, 0};\n#else\nstatic int sig\[\] = { SIGHUP, SIGINT, SIGPIPE, SIGTERM, 0};\n#endif^" ${DISTDIR}/as/as.c
    do_sed $"s^    const char \*AS = \"/as\";^#ifdef __MINGW32__\n    const char \*AS = \"/as.exe\";\n#else\n    const char \*AS = \"/as\";\n#endif^" ${DISTDIR}/as/driver.c
    do_sed $"s^#include <string.h>^#include <string.h>\n#ifdef __MINGW32__\n#include <malloc.h>\n#endif^" ${DISTDIR}/as/atof-generic.c
    do_sed $"s^#include <string.h>^#include <string.h>\n#ifdef __MINGW32__\n#include <malloc.h>\n#endif^" ${DISTDIR}/as/arm.c
    do_sed $"s^#include <string.h>^#include <string.h>\n#ifdef __MINGW32__\n#include <malloc.h>\n#endif^" ${DISTDIR}/as/i386.c
fi
do_sed $"s^#include <stdlib.h>^#include <stdlib.h>\n#include <stdint.h>\n^" ${DISTDIR}/as/obstack.c

# libprunetrie
do_sed $"s^#include <vector>^#include <stdio.h>\n#include <vector>^" ${DISTDIR}/libprunetrie/PruneTrie.cpp

# libmacho
# do_sed $"s^#include <mach-o/arch.h>^#include <mach-o/arch.h>\n#include "config.h"\n^" ${DISTDIR}/libmacho/arch.c

# ld, misc
do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#endif^" ${DISTDIR}/misc/checksyms.c
do_sed $"s^#include <limits.h>^#include <limits.h>\n#if !defined(ULLONG_MAX)\n#define ULLONG_MAX (__LONG_LONG_MAX__ * 2ULL + 1ULL)\n#endif\n^" ${DISTDIR}/misc/install_name_tool.c

if [[ "$(uname_bt)" = "Linux" ]] || [[ "$(uname_bt)" = "Darwin" ]] ; then
    do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <unistd.h>\n#endif^" ${DISTDIR}/ld/ld.c
    do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <unistd.h>\n#endif^" ${DISTDIR}/ld/pass1.c
    do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <unistd.h>\n#endif^" ${DISTDIR}/ld/pass2.c
    do_sed $"s^extern \"C\" double log2 ( double );^#ifdef __APPLE__\nextern \"C\" double log2 ( double );\n#else\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <unistd.h>\n#endif^" ${DISTDIR}/ld64/src/ld/ld.cpp
    do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <unistd.h>\n#endif^" ${DISTDIR}/ld64/src/ld/Options.cpp
    do_sed $"s^#include <vector>^#include <vector>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <unistd.h>\n#include <string.h>\n#include <stdarg.h>\n#endif^" ${DISTDIR}/ld64/src/ld/Options.cpp
    do_sed $"s^#include <vector>^#include <vector>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <unistd.h>\n#include <string.h>\n#include <stdarg.h>\n#endif^" ${DISTDIR}/ld64/src/ld/InputFiles.cpp
    do_sed $"s^#include <vector>^#include <vector>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <unistd.h>\n#include <string.h>\n#include <stdarg.h>\n#endif^" ${DISTDIR}/ld64/src/ld/OutputFile.cpp
    do_sed $"s^#include <vector>^#include <vector>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <unistd.h>\n#include <string.h>\n#include <stdarg.h>\n#endif^" ${DISTDIR}/ld64/src/ld/SymbolTable.cpp
    do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <stdlib.h>\n#include <unistd.h>\n#endif^" ${DISTDIR}/misc/lipo.c
elif [[ "$(uname_bt)" = "Windows" ]] ; then
    do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <io.h>\n#endif^" ${DISTDIR}/ld/ld.c
    do_sed $"s^if(signal(SIGBUS, SIG_IGN) != SIG_IGN)^#ifndef __MINGW32__\nif(signal(SIGBUS, SIG_IGN) != SIG_IGN)^" ${DISTDIR}/ld/ld.c
    do_sed $"s^signal(SIGBUS, handler);^signal(SIGBUS, handler);\n#endif^" ${DISTDIR}/ld/ld.c
    do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <io.h>\n#endif^" ${DISTDIR}/ld/pass1.c
    do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <io.h>\n#endif^" ${DISTDIR}/ld/pass2.c
    do_sed $"s^extern \"C\" double log2 ( double );^#ifdef __APPLE__\nextern \"C\" double log2 ( double );\n#else\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <io.h>\n#endif^" ${DISTDIR}/ld64/src/ld/ld.cpp
    do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <io.h>\n#endif^" ${DISTDIR}/ld64/src/ld/Options.cpp
    do_sed $"s^#include <vector>^#include <vector>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <io.h>\n#include <string.h>\n#include <stdarg.h>\n#endif^" ${DISTDIR}/ld64/src/ld/Options.cpp
    do_sed $"s^#include <vector>^#include <vector>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <io.h>\n#include <string.h>\n#include <stdarg.h>\n#endif^" ${DISTDIR}/ld64/src/ld/InputFiles.cpp
    do_sed $"s^#include <vector>^#include <vector>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <io.h>\n#include <string.h>\n#include <stdarg.h>\n#endif^" ${DISTDIR}/ld64/src/ld/OutputFile.cpp
    do_sed $"s^#include <vector>^#include <vector>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <io.h>\n#include <string.h>\n#include <stdarg.h>\n#endif^" ${DISTDIR}/ld64/src/ld/SymbolTable.cpp
    do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <stdlib.h>\n#include <io.h>\n#endif^" ${DISTDIR}/misc/lipo.c
    do_sed $"s^#include <sys/mman.h>^#ifndef __MINGW32__\n#include <sys/mman.h>\n#endif^" ${DISTDIR}/misc/lipo.c
    do_sed $"s^#include <sys/mman.h>^#ifndef __MINGW32__\n#include <sys/mman.h>\n#endif^" ${DISTDIR}/misc/libtool.c
    do_sed $"s^#include <sys/mman.h>^#ifndef __MINGW32__\n#include <sys/mman.h>\n#endif^" ${DISTDIR}/misc/segedit.c
fi
do_sed $"s^void __assert_rtn(const char\* func, const char\* file, int line, const char\* failedexpr)^extern \"C\" void __assert_rtn(const char\* func, const char\* file, int line, const char\* failedexpr);\nvoid __assert_rtn(const char\* func, const char\* file, int line, const char\* failedexpr)\n^" ${DISTDIR}/ld64/src/ld/ld.cpp
do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <sys/file.h>\n#endif^" ${DISTDIR}/misc/libtool.c
do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <sys/file.h>\n#endif^" ${DISTDIR}/misc/redo_prebinding.c
do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <sys/file.h>\n#endif^" ${DISTDIR}/misc/indr.c
do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <sys/file.h>\n#endif^" ${DISTDIR}/misc/strip.c
do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <sys/file.h>\n#endif^" ${DISTDIR}/misc/segedit.c
do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <sys/file.h>\n#endif^" ${DISTDIR}/otool/main.c
do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <sys/file.h>\n#include <sys/stat.h>\n#endif^" ${DISTDIR}/otool/ofile_print.c
do_sed $"s^#define __dr7 dr7^#define __dr7 dr7\n#ifndef __APPLE__\n#define FP_PREC_24B 0\n#define FP_PREC_53B 2\n#define FP_PREC_64B 3\n#define FP_RND_NEAR 0\n#define FP_RND_DOWN 1\n#define FP_RND_UP 2\n#define FP_CHOP 3\n#endif^" ${DISTDIR}/otool/ofile_print.c

do_sed $"s^#include <unistd.h>^#include <unistd.h>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#endif^" ${DISTDIR}/ld64/src/ld/passes/branch_island.cpp
do_sed $"s^#include <unistd.h>^#include <unistd.h>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#endif^" ${DISTDIR}/ld64/src/ld/passes/branch_shim.cpp
do_sed $"s^#include <unistd.h>^#include <unistd.h>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#endif^" ${DISTDIR}/ld64/src/ld/passes/compact_unwind.cpp
do_sed $"s^#include <unistd.h>^#include <unistd.h>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#endif^" ${DISTDIR}/ld64/src/ld/passes/dtrace_dof.cpp
do_sed $"s^#include <unistd.h>^#include <unistd.h>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#endif^" ${DISTDIR}/ld64/src/ld/passes/dtrace_dof.cpp
do_sed $"s^#include <stdint.h>^#include <stdint.h>\n#ifndef __APPLE__\n#include <string.h>\n#endif^" ${DISTDIR}/ld64/src/ld/passes/dylibs.cpp
do_sed $"s^#include <stdint.h>^#include <stdint.h>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <string.h>\n#endif^" ${DISTDIR}/ld64/src/ld/passes/got.cpp
do_sed $"s^#include <stdint.h>^#include <stdint.h>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <string.h>\n#endif^" ${DISTDIR}/ld64/src/ld/passes/huge.cpp
do_sed $"s^#include <stdint.h>^#include <stdint.h>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <string.h>\n#endif^" ${DISTDIR}/ld64/src/ld/passes/order_file.cpp
do_sed $"s^#include <stdint.h>^#include <stdint.h>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <string.h>\n#endif^" ${DISTDIR}/ld64/src/ld/passes/stubs/stubs.cpp
do_sed $"s^#include <stdint.h>^#include <stdint.h>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <string.h>\n#endif^" ${DISTDIR}/ld64/src/ld/passes/tlvp.cpp
do_sed $"s^#include <vector>^#include <vector>\n#ifndef __APPLE__\n#include <string.h>\n#endif^" ${DISTDIR}/ld64/src/ld/parsers/opaque_section_file.cpp
do_sed $"s^#include <vector>^#include <vector>\n#ifndef __APPLE__\n#include <string.h>\n#endif^" ${DISTDIR}/ld64/src/ld/parsers/opaque_section_file.cpp
do_sed $"s^#include <stdlib.h>^#include <stdlib.h>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <string.h>\n#endif^" ${DISTDIR}/ld64/src/ld/parsers/lto_file.cpp
do_sed $"s^#include <stdint.h>^#include <stdint.h>\n#ifndef __APPLE__\n#include <stdio.h>\n#include <string.h>\n#define AR_EFMT1 \"#1/\"\n#endif^" ${DISTDIR}/ld64/src/ld/parsers/archive_file.cpp
do_sed $"s^#include <unistd.h>^#include <unistd.h>\n#ifndef __APPLE__\n#include <uuid/uuid.h>\n#endif^" ${DISTDIR}/ld64/include/mach-o/dyld_images.h

if [[ "$(uname_bt)" = "Windows" ]] ; then
    do_sed $"s^#include <sys/mman.h>^#ifndef __MINGW32__\n#include <sys/mman.h>\n#endif^" ${DISTDIR}/ld64/src/ld/ld.cpp
    do_sed $"s^#include <sys/mman.h>^#ifndef __MINGW32__\n#include <sys/mman.h>\n#endif^" ${DISTDIR}/ld64/src/ld/InputFiles.cpp
    do_sed $"s^#include <sys/mman.h>^#ifndef __MINGW32__\n#include <sys/mman.h>\n#endif^" ${DISTDIR}/ld64/src/ld/InputFiles.h
    do_sed $"s^#include <sys/mman.h>^#ifndef __MINGW32__\n#include <sys/mman.h>\n#endif^" ${DISTDIR}/ld64/src/ld/SymbolTable.cpp
    do_sed $"s^#include <sys/mman.h>^#ifndef __MINGW32__\n#include <sys/mman.h>\n#endif^" ${DISTDIR}/ld64/src/ld/SymbolTable.h
    do_sed $"s^#include <sys/mman.h>^#ifndef __MINGW32__\n#include <sys/mman.h>\n#endif^" ${DISTDIR}/ld64/src/ld/Resolver.cpp
    do_sed $"s^#include <sys/mman.h>^#ifndef __MINGW32__\n#include <sys/mman.h>\n#endif^" ${DISTDIR}/ld64/src/ld/Resolver.h
    do_sed $"s^#include <sys/mman.h>^#ifndef __MINGW32__\n#include <sys/mman.h>\n#endif^" ${DISTDIR}/ld64/src/ld/OutputFile.cpp
    do_sed $"s^#include <sys/mman.h>^#ifndef __MINGW32__\n#include <sys/mman.h>\n#endif^" ${DISTDIR}/ld64/src/ld/OutputFile.h
    do_sed $"s^#include <sys/mman.h>^#ifndef __MINGW32__\n#include <sys/mman.h>\n#endif^" ${DISTDIR}/ld64/src/ld/parsers/macho_relocatable_file.cpp
    do_sed $"s^#include <sys/mman.h>^#ifndef __MINGW32__\n#include <sys/mman.h>\n#endif^" ${DISTDIR}/ld64/src/ld/parsers/macho_dylib_file.cpp

    # Linux has sysctl, but they won't be compatible so only for Apple.
    do_sed $"s^#include <sys/sysctl.h>^#ifdef __APPLE__\n#include <sys/sysctl.h>\n#endif^" ${DISTDIR}/ld64/src/ld/ld.cpp
    do_sed $"s^#include <sys/sysctl.h>^#ifdef __APPLE__\n#include <sys/sysctl.h>\n#endif^" ${DISTDIR}/ld64/src/ld/InputFiles.cpp
    do_sed $"s^#include <sys/sysctl.h>^#ifdef __APPLE__\n#include <sys/sysctl.h>\n#endif^" ${DISTDIR}/ld64/src/ld/InputFiles.h
    do_sed $"s^#include <sys/sysctl.h>^#ifdef __APPLE__\n#include <sys/sysctl.h>\n#endif^" ${DISTDIR}/ld64/src/ld/SymbolTable.cpp
    do_sed $"s^#include <sys/sysctl.h>^#ifdef __APPLE__\n#include <sys/sysctl.h>\n#endif^" ${DISTDIR}/ld64/src/ld/SymbolTable.h
    do_sed $"s^#include <sys/sysctl.h>^#ifdef __APPLE__\n#include <sys/sysctl.h>\n#endif^" ${DISTDIR}/ld64/src/ld/Resolver.cpp
    do_sed $"s^#include <sys/sysctl.h>^#ifdef __APPLE__\n#include <sys/sysctl.h>\n#endif^" ${DISTDIR}/ld64/src/ld/Resolver.h
    do_sed $"s^#include <sys/sysctl.h>^#ifdef __APPLE__\n#include <sys/sysctl.h>\n#endif^" ${DISTDIR}/ld64/src/ld/OutputFile.cpp
    do_sed $"s^#include <sys/sysctl.h>^#ifdef __APPLE__\n#include <sys/sysctl.h>\n#endif^" ${DISTDIR}/ld64/src/ld/OutputFile.h
    do_sed $"s^#include <execinfo.h>^#ifndef __MINGW32__\n#include <execinfo.h>\n#endif^" ${DISTDIR}/ld64/src/ld/ld.cpp
fi

# qsort_r on linux has the last 2 parameters swapped wrt darwin...
# Also, the swap function is all swapped around, darwin it's:
# int (*)(void*, const void*, const void*)
# Linux it's
# int (*)(const void*, const void*, void*)
# That is not handled yet...
if [[ "$(uname_bt)" = "Linux" ]] ; then
    do_sed $"s^symbol_address_compare);^\&has_stabs);^"  ${DISTDIR}/ld/pass1.c
    do_sed $"s^qsort_r (sst, cur_obj->symtab->nsyms, sizeof (struct nlist \*), \&has_stabs,^qsort_r (sst, cur_obj->symtab->nsyms, sizeof (struct nlist \*), symbol_address_compare,^" ${DISTDIR}/ld/pass1.c
    do_sed $"s^(void \*fail_p, const void \*a_p, const void \*b_p)^(const void \*a_p, const void \*b_p, void \*fail_p)^" ${DISTDIR}/ld/pass1.c
fi

# GCC <= 4.4.3 doesn't like this whereas GCC >= 4.6 needs this, so fix it on everything except Darwin.
if [[ ! "$(uname_bt)" = "Darwin" ]] ; then
    do_sed $"s^libunwind::CFI_Atom_Info<CFISection<^typename libunwind::CFI_Atom_Info<CFISection<^" ${DISTDIR}/ld64/src/ld/parsers/macho_relocatable_file.cpp
fi

do_sed $"s^#define VM_SYNC_DEACTIVATE      ((vm_sync_t) 0x10)^#ifdef __APPLE__\n#define VM_SYNC_DEACTIVATE      ((vm_sync_t) 0x10)\n#else\n#include <stdio.h>\n#endif^" ${DISTDIR}/include/mach/vm_sync.h

do_sed $"s^#include <stdint.h>^#include <stdint.h>\n#ifndef __APPLE__\n#include <stdio.h>\n#endif^" ${DISTDIR}/ld64/src/ld/parsers/macho_dylib_file.cpp

if [[ ! "$(uname_bt)" = "Darwin" ]] ; then
	do_sed $"s^#include <CommonCrypto/CommonDigest.h>^#include <openssl/md5.h>^" ${DISTDIR}/ld64/src/ld/OutputFile.cpp
	do_sed $"s^CC_MD5^MD5^" ${DISTDIR}/ld64/src/ld/OutputFile.cpp
fi

# Fix binary files being written out (and read in) as ascii on Windows. It'd be better if could just turn off ascii reads and writes.
if [[ "$(uname_bt)" = "Windows" ]] ; then
    do_sed $"s^O_WRONLY | O_CREAT | O_TRUNC^O_WRONLY | O_CREAT | O_TRUNC | O_BINARY^"   ${DISTDIR}/ld/rld.c
    do_sed $"s^O_WRONLY | O_CREAT | O_TRUNC^O_WRONLY | O_CREAT | O_TRUNC | O_BINARY^"   ${DISTDIR}/as/write_object.c
    do_sed $"s^O_WRONLY^O_WRONLY | O_BINARY^"                                           ${DISTDIR}/misc/libtool.c
    do_sed $"s^O_WRONLY | O_CREAT | O_TRUNC^O_WRONLY | O_CREAT | O_TRUNC | O_BINARY^"   ${DISTDIR}/misc/lipo.c
    do_sed $"s^O_CREAT|O_RDWR^O_CREAT|O_RDWR|O_BINARY^"                                 ${DISTDIR}/ar/append.c
    do_sed $"s^O_CREAT|O_RDWR^O_CREAT|O_RDWR|O_BINARY^"                                 ${DISTDIR}/ar/replace.c
    do_sed $"s^O_RDONLY)^O_RDONLY|O_BINARY)^"                                           ${DISTDIR}/ar/replace.c
    do_sed $"s^O_CREAT | O_EXLOCK | O_RDWR^O_CREAT | O_EXLOCK | O_RDWR | O_BINARY^"     ${DISTDIR}/dyld/launch-cache/dsc_extractor.cpp
    do_sed $"s^O_CREAT | O_RDWR | O_TRUNC^O_CREAT | O_RDWR | O_TRUNC | O_BINARY^"       ${DISTDIR}/dyld/launch-cache/update_dyld_shared_cache.cpp
    do_sed $"s^O_CREAT | O_RDWR | O_TRUNC^O_CREAT | O_RDWR | O_TRUNC | O_BINARY^"       ${DISTDIR}/dyld/launch-cache/update_dyld_shared_cache.cpp
    do_sed $"s^O_WRONLY|O_CREAT|O_TRUNC^O_WRONLY|O_CREAT|O_TRUNC|O_BINARY^"             ${DISTDIR}/efitools/makerelocs.c
    do_sed $"s^O_WRONLY|O_CREAT|O_TRUNC^O_WRONLY|O_CREAT|O_TRUNC|O_BINARY^"             ${DISTDIR}/efitools/mtoc.c
    do_sed $"s^archive, mode^archive, mode|O_BINARY^"                                   ${DISTDIR}/ar/archive.c
    do_sed $"s^O_WRONLY|O_CREAT|O_TRUNC^O_WRONLY|O_CREAT|O_TRUNC|O_BINARY^"             ${DISTDIR}/ar/extract.c
    do_sed $"s^O_TRUNC, 0666^O_TRUNC | O_BINARY, 0666^"                                 ${DISTDIR}/misc/segedit.c
    do_sed $"s^O_WRONLY|O_CREAT|O_TRUNC|fsync^O_WRONLY|O_CREAT|O_TRUNC|O_BINARY|fsync^" ${DISTDIR}/libstuff/writeout.c
    do_sed $"s^O_RDONLY^O_RDONLY|O_BINARY^"                                             ${DISTDIR}/libstuff/ofile.c
    do_sed $"s^O_CREAT | O_WRONLY | O_TRUNC^O_CREAT | O_WRONLY | O_TRUNC | O_BINARY^"   ${DISTDIR}/ld64/src/ld/OutputFile.cpp
    do_sed $"s^O_CREAT | O_WRONLY | O_TRUNC^O_CREAT | O_WRONLY | O_TRUNC | O_BINARY^"   ${DISTDIR}/ld64/src/ld/lto_file.hpp
    do_sed $"s^O_CREAT | O_WRONLY | O_TRUNC^O_CREAT | O_WRONLY | O_TRUNC | O_BINARY^"   ${DISTDIR}/ld64/src/ld/parsers/lto_file.cpp
    do_sed $"s^O_CREAT | O_RDWR | O_TRUNC^O_CREAT | O_RDWR | O_TRUNC | O_BINARY^"       ${DISTDIR}/ld64/src/other/rebase.cpp
    do_sed $"s^O_RDWR : O_RDONLY^O_RDWR|O_BINARY : O_RDONLY|O_BINARY^"                  ${DISTDIR}/ld64/src/other/rebase.cpp
    do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <io.h>\n#endif^" ${DISTDIR}/ld64/src/ld/Options.cpp
    do_sed $"s^O_RDONLY, 0)^O_RDONLY|O_BINARY, 0)^"                                     ${DISTDIR}/ld64/src/ld/Options.cpp
    do_sed $"s^O_CREAT | O_WRONLY | O_TRUNC ^O_CREAT | O_WRONLY | O_TRUNC | O_BINARY^"  ${DISTDIR}/misc/segedit.c
    do_sed $"s^O_RDONLY^O_RDONLY|O_BINARY^"                                             ${DISTDIR}/misc/segedit.c
    do_sed $"s^O_WRONLY|O_CREAT^O_WRONLY|O_CREAT|O_BINARY^"                             ${DISTDIR}/misc/strip.c
    do_sed $"s^O_RDONLY^O_RDONLY|O_BINARY^"                                             ${DISTDIR}/misc/strip.c
fi

do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/ld/rld.c
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/ld/ld.c
do_sed $"s^0777^FIO_READ_WRITE_EXEC^" ${DISTDIR}/ld/pass2.c
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/as/write_object.c
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/dyld/src/dyld.cpp
do_sed $"s^0777^FIO_READ_WRITE_EXEC^" ${DISTDIR}/dyld/src/dyld.cpp
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/misc/libtool.c
do_sed $"s^07777^FIO_MASK_ALL_4^"     ${DISTDIR}/misc/lipo.c
do_sed $"s^0777^FIO_READ_WRITE_EXEC^" ${DISTDIR}/misc/codesign_allocate.c
do_sed $"s^0777^FIO_READ_WRITE_EXEC^" ${DISTDIR}/misc/ctf_insert.c
do_sed $"s^0644^FIO_READ_WRITE^"      ${DISTDIR}/dyld/launch-cache/dsc_extractor.cpp
do_sed $"s^0644^FIO_READ_WRITE^"      ${DISTDIR}/dyld/launch-cache/update_dyld_shared_cache.cpp
do_sed $"s^0644^FIO_READ_WRITE^"      ${DISTDIR}/efitools/makerelocs.c
do_sed $"s^0644^FIO_READ_WRITE^"      ${DISTDIR}/efitools/mtoc.c
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/ld64/src/ld/InputFiles.cpp
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/misc/segedit.c
do_sed $"s^07777^FIO_MASK_ALL_4^"     ${DISTDIR}/misc/redo_prebinding.c
do_sed $"s^0777^FIO_READ_WRITE_EXEC^" ${DISTDIR}/misc/inout.c
do_sed $"s^0777^FIO_READ_WRITE_EXEC^" ${DISTDIR}/misc/install_name_tool.c
do_sed $"s^0777^FIO_READ_WRITE_EXEC^" ${DISTDIR}/ld64/src/ld/OutputFile.cpp
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/ld64/src/ld/OutputFile.cpp
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/ld64/src/ld/lto_file.hpp
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/ld64/src/ld/parsers/lto_file.cpp
do_sed $"s^0600^FIO_READ_WRITE_ME^"   ${DISTDIR}/misc/strip.c
do_sed $"s^0777^FIO_READ_WRITE_EXEC^" ${DISTDIR}/misc/strip.c

AUTOHEADER=autoheader
AUTOCONF=autoconf
# Fix temporary file location in tmp() in ar/misc.c
if [[ "$(uname_bt)" = "Windows" ]] ; then
    do_sed $"s^TMPDIR^TEMP^"    ${DISTDIR}/ar/misc.c
    # Oddly, getenv("TEMP") on MinGW is returning "C:/Users/blah/LocalSettings/Temp", probably want to detect the slashes returned and play along instead of this.
    do_sed $"s^%s/%s^%s\\\\\\\\%s^" ${DISTDIR}/ar/misc.c
    if [ -d /opt/autotools/bin ]; then
        PATH=/opt/autotools/bin:$PATH
        AUTOCONF=autoconf-2.68
        AUTOHEADER=autoheader-2.68
    fi
fi

# Attempt fix for ar header output:
#define	HDR1	"%s%-13d%-12ld%-6u%-6u%-8o%-10qd%2s"
# MinGW falls over, possibly because pformat.c doesn't handle qd, so instead, change it lld.
if [[ "$(uname_bt)" = "Windows" ]] ; then
    do_sed $"s^10qd^10lld^"    ${DISTDIR}/ar/archive.h
fi

message_status "Deleting cruft"
find ${DISTDIR} -name Makefile -exec rm -f "{}" \;
find ${DISTDIR} -name \*~ -exec rm -f "{}" \;
find ${DISTDIR} -name .\#\* -exec rm -f "{}" \;

pushd ${DISTDIR} > /dev/null
$AUTOHEADER
$AUTOCONF
rm -rf autom4te.cache
popd > /dev/null

if [ $MAKEDISTFILE -eq 1 ]; then
    DATE=$(date +%Y%m%d)
    mv ${DISTDIR} ${DISTDIR}-$DATE
    tar jcf ${DISTDIR}-$DATE.tar.bz2 ${DISTDIR}-$DATE
fi
#patch odcctools-${CCTOOLSVERS}${FOREIGNHEADERS}/misc/Makefile.in < $PATCHFILESDIR/misc/Makefile.in.diff
