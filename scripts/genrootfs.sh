#!/bin/sh -e

cleanup() {
	rm -rf "$tmp"
}

rc_add() {
	mkdir -p "$tmp"/etc/runlevels/$2
	ln -sf /etc/init.d/$1 "$tmp"/etc/runlevels/$2/$1
}

tmp="$(mktemp -d)"
#trap cleanup EXIT
chmod 0755 "$tmp"

arch="$(apk --print-arch)"
repositories_file=`dirname $0`/../confs/etc/apk/repositories
keys_dir=/etc/apk/keys

while getopts "a:r:k:o:" opt; do
	case $opt in
	a) arch="$OPTARG";;
	r) repositories_file="$OPTARG";;
	k) keys_dir="$OPTARG";;
	o) outfile="$OPTARG";;
	esac
done
shift $(( $OPTIND - 1))

cat "$repositories_file"

if [ -z "$outfile" ]; then
	outfile=rootfs-$arch.squashfs
fi

${APK:-apk} add --keys-dir "$keys_dir" --no-cache \
	--repositories-file "$repositories_file" \
	--no-script --root "$tmp" --initdb --arch "$arch" \
	$@
for link in $("$tmp"/bin/busybox --list-full); do
	[ -e "$tmp"/$link ] || ln -s /bin/busybox "$tmp"/$link
done

${APK:-apk} fetch --keys-dir "$keys_dir" --no-cache \
	--repositories-file "$repositories_file" --root "$tmp" \
	--stdout --quiet alpine-base | tar -zx -C "$tmp" etc/

# make sure root login is disabled but allown ssh login
#sed -i -e 's/^root::/root:*:/' "$tmp"/etc/shadow


# set timezone
ln -s /usr/share/zoneinfo/America/Guayaquil "$tmp"/etc/localtime

#set hostname
echo "aeolia" > "$tmp"/etc/hostname

#generate ssh host key
ssh-keygen -A -f "$tmp"

# copy all customed files to /etc
cp -r `dirname $0`/../confs/etc/* $tmp/etc/
# add rfcomm0 in securetty file
echo rfcomm0 >> $tmp/etc/securetty

#copy authorized key to /root
mkdir -p "$tmp"/root/.ssh
chmod 700 "$tmp"/root/.ssh
cp `dirname $0`/../confs/authorized_keys "$tmp"/root/.ssh
chmod 644 "$tmp"/root/.ssh/authorized_keys

# install ruby-gem in chroot
`dirname $0`/chroot-install.sh $tmp

# change bluetooth start options
sed -i '/#Name /s/.*/Name = PS4/' $tmp/etc/bluetooth/main.conf
sed -i '/^#AutoEnable/s/.*/AutoEnable=true/' $tmp/etc/bluetooth/main.conf
sed -i '/^#DiscoverableTimeout/s/.*/DiscoverableTimeout=0/' $tmp/etc/bluetooth/main.conf
sed -i '/^#AlwaysPairable/s/.*/AlwaysPairable=true/' $tmp/etc/bluetooth/main.conf

# set service started on boot
for serv in devfs dmesg mdev hwclock hwdrivers; do
	rc_add $serv "sysinit"
done

for serv in modules sysctl hostname syslog dbus bluetooth\
	networking wpa_supplicnat wpa_cli; do
	rc_add $serv "boot"
done

for serv in killprocs; do
	rc_add $serv "shutdown"
done

for serv in sshd chronyd local; do
	rc_add $serv "default"
done

#copy modules
mkdir -p $tmp/lib/modules
cp -r /lib/modules/* $tmp/lib/modules/


mksquashfs "$tmp" "$outfile"  -comp xz -b 1024k -always-use-fragments -noappend -wildcards -e 'dev/*' 
