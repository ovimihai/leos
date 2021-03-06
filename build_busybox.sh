#!/bin/sh
set -ex

if [ ! -f busybox.tar.bz2 ]; then
	wget -q -O busybox.tar.bz2 http://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2
fi

if [ -d busybox-$BUSYBOX_VERSION ]; then
	rm -rf busybox-$BUSYBOX_VERSION
fi

tar -xjf busybox.tar.bz2

cd busybox-$BUSYBOX_VERSION

make -j5 distclean
make -j5 defconfig

export SYSROOT=`realpath ../glibc_install/`

sed -i "s/.*CONFIG_STATIC.*/CONFIG_STATIC=y/" .config
sed -i "s|.*CONFIG_SYSROOT.*|CONFIG_SYSROOT=\"$SYSROOT\"|" .config

make -j5 busybox install
cd _install
rm -f linuxrc

cp -Rv ../../rootfs/* .
find . -iname ".gitkeep" -exec rm {} \;

mkdir -p lib
cp ../../glibc_install/lib/libnss* lib/
cp ../../glibc_install/lib/libresolv* lib/
cp ../../glibc_install/lib/libc.* lib/
cp ../../glibc_install/lib/libc-* lib/
cp ../../glibc_install/lib/libthread* lib/
cp ../../glibc_install/lib/ld* lib/

set +e
strip -g lib/*
set -e

find . | cpio -R root:root -H newc -o | xz -9 --check=none > ../../isoimage/rootfs.xz

cd ../../
set +ex
