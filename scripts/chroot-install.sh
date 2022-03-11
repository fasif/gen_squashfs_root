#!/bin/sh -e

mount_chroot() {
	mount -t proc none $1/proc
	mount -o bind /dev $1/dev
	mount -o bind /sys $1/sys
}

umount_chroot() {
	for dir in proc dev sys; do
		umount $1/$dir
	done
}

rootdir=$1
cleanup() {
	umount_chroot $rootdir 
}

mount_chroot $rootdir
trap cleanup EXIT

cat <<EOF
chroot: install chrony bluez blue-deprecated
	docker ruby vim screen
EOF
chroot $rootdir /sbin/apk add chrony bluez bluez-deprecated \
	docker ruby vim make mkinitfs squashfs-tools screen curl

echo "chroot: gem install ruby-dbus"
chroot $rootdir /usr/bin/gem install ruby-dbus
