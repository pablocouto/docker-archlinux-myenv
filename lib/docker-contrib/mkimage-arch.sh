#!/usr/bin/env bash

# Copyright 2012-2015 Docker, Inc.
# Copyright 2015 Pablo Couto

# Modified to avoid the creation of a new docker image, if the state of Arch
# repos hasn’t changed since that of the last image created and still available.

# Generate a minimal filesystem for archlinux and load it into the local
# docker as "archlinux"
# requires root
set -e

hash ./pacstrap &>/dev/null || {
	echo "Could not find pacstrap. Run pacman -S arch-install-scripts"
	exit 1
}

hash expect &>/dev/null || {
	echo "Could not find expect. Run pacman -S expect"
	exit 1
}

export LANG="C.UTF-8"

TMPDIR=${TMPDIR:-/var/tmp}
TMPREPSLBL=$(mktemp $TMPDIR/repos_label-XXXXXXXXXX)
ROOTFS=$(mktemp -d $TMPDIR/rootfs-archlinux-XXXXXXXXXX)
chmod 755 $ROOTFS

# packages to ignore for space savings
PKGIGNORE=(
    cryptsetup
    device-mapper
    dhcpcd
    iproute2
    jfsutils
    linux
    lvm2
    man-db
    man-pages
    mdadm
    nano
    netctl
    openresolv
    pciutils
    pcmciautils
    reiserfsprogs
    s-nail
    systemd-sysvcompat
    usbutils
    vi
    xfsprogs
)
IFS=','
PKGIGNORE="${PKGIGNORE[*]}"
unset IFS

function initialize()
{
  expect <<EOF
          set send_slow {1 .1}
          proc send {ignore arg} {
                  sleep .1
                  exp_send -s -- \$arg
          }
          set timeout 60

          spawn ./pacstrap -C ./mkimage-arch-pacman.conf -c -d -G -i $ROOTFS base haveged --ignore $PKGIGNORE
          set pacstrap_spawn_id \$spawn_id

          expect -re {^.*Repos state label: ([a-f0-9]*)\. Continue\? \[y/n\] } {
                   set label \$expect_out(1,string)
                   puts [open $TMPREPSLBL w] \$label
                   spawn -noecho docker inspect archlinux-\$label
                   lassign [wait] pid docker_spawn_id osexitcode docker_spawnexitcode
                   set spawn_id \$pacstrap_spawn_id
                   if {\$docker_spawnexitcode == 0} {
                     send -- "n\r"
                     puts "\nAn image with repos label \$label already exists. Exiting."
                     exit 1
                   } else {
                     send -- "y\r"
                   }
                 }

          expect {
                  -exact "anyway? \[Y/n\] " { send -- "n\r"; exp_continue }
                  -exact "(default=all): " { send -- "\r"; exp_continue }
                  -exact "installation? \[Y/n\]" { send -- "y\r"; exp_continue }
          }
EOF
}

initialize

arch-chroot $ROOTFS /bin/sh -c 'rm -r /usr/share/man/*'
arch-chroot $ROOTFS /bin/sh -c "haveged -w 1024; pacman-key --init; pkill haveged; pacman -Rs --noconfirm haveged; pacman-key --populate archlinux; pkill gpg-agent"
arch-chroot $ROOTFS /bin/sh -c "ln -s /usr/share/zoneinfo/UTC /etc/localtime"
echo 'en_US.UTF-8 UTF-8' > $ROOTFS/etc/locale.gen
arch-chroot $ROOTFS locale-gen
arch-chroot $ROOTFS /bin/sh -c 'echo "Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist'

# udev doesn't work in containers, rebuild /dev
DEV=$ROOTFS/dev
rm -rf $DEV
mkdir -p $DEV
mknod -m 666 $DEV/null c 1 3
mknod -m 666 $DEV/zero c 1 5
mknod -m 666 $DEV/random c 1 8
mknod -m 666 $DEV/urandom c 1 9
mkdir -m 755 $DEV/pts
mkdir -m 1777 $DEV/shm
mknod -m 666 $DEV/tty c 5 0
mknod -m 600 $DEV/console c 5 1
mknod -m 666 $DEV/tty0 c 4 0
mknod -m 666 $DEV/full c 1 7
mknod -m 600 $DEV/initctl p
mknod -m 666 $DEV/ptmx c 5 2
ln -sf /proc/self/fd $DEV/fd

REPOS_LABEL=$(cat $TMPREPSLBL)
tar --numeric-owner --xattrs --acls -C $ROOTFS -c . | docker import - archlinux-$REPOS_LABEL
docker run -t archlinux-$REPOS_LABEL echo Success.
sed -i -e "s/^FROM archlinux-[a-f0-9]*$/FROM archlinux-$REPOS_LABEL/g" Dockerfile
rm -rf $ROOTFS
rm $TMPREPSLBL
