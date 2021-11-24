#!/bin/bash

# 3000makefs.sh
#
# setup a simple chrooted environment in a new
# filesystem (created in a local file)
#
# Initial version by Anil Somayaji
# created November 12, 2021
#

MP='3000fs'
IMAGE='3000fsimage'
BLOCKS=100000
SETUP='3000setupfs.sh'

if [ $UID != 0 ]; then
    echo "Please run this script as root."
    exit
fi

rm -f $IMAGE
dd if=/dev/zero of=$IMAGE bs=4096 count=$BLOCKS
mkfs.ext4 $IMAGE

if [ -d $MP ]; then
    umount -q $MP/proc
    umount -q $MP
    rm -rf $MP
fi

mkdir $MP
mount $IMAGE $MP
cd $MP

mkdir bin sbin usr usr/bin usr/sbin etc proc sys dev root home lib \
      usr/lib  lib64 tmp var var/tmp var/lib run lib/terminfo
cp /usr/bin/busybox usr/bin

cp /bin/bash bin
cp /lib64/ld-linux-x86-64.so.2 lib64
cp /sbin/ldconfig* sbin
cp -a /etc/ld.so.conf* etc

cp `ldd /bin/bash | awk '{print $3}'` lib

chmod 1777 tmp var/tmp

cp -a /etc/passwd /etc/shadow /etc/group /etc/gshadow etc

TERMDIR=${TERM:0:1}
mkdir lib/terminfo/$TERMDIR
cp /lib/terminfo/$TERMDIR/$TERM lib/terminfo/$TERMDIR/$TERM

echo '#!/usr/bin/busybox sh' > $SETUP
echo '/usr/bin/busybox --install -s' >> $SETUP
echo '/sbin/ldconfig' >> $SETUP
echo 'mount -t proc proc /proc' >> $SETUP
echo 'mount -t devtmpfs udev /dev' >> $SETUP

chmod 0755 $SETUP
chroot . /$SETUP
rm $SETUP
chroot .
