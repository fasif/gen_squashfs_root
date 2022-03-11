arch := $(shell apk --print-arch)
minirootfs := busybox alpine-baselayout alpine-keys apk-tools libc-utils
apks := $(minirootfs) openrc tzdata openssh sudo cryptsetup \
	wpa_supplicant busybox-initscripts

all: initramfs.cpio.gz rootfs-$(arch).squashfs
initramfs.cpio.gz:
	mkinitfs -i ./confs/init -c ./confs/mkinitfs.conf -o initramfs.cpio.gz
rootfs-$(arch).squashfs:
	./scripts/genrootfs.sh $(apks)
clean:
	rm rootfs-$(arch).squashfs initramfs.cpio.gz
