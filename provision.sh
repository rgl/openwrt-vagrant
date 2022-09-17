#!/bin/ash
set -euxo pipefail

# update the packages metadata.
opkg update

# resize the rootfs partition to fill the entire disk.
# NB /dev/sda1 contains the bootfs.
# NB /dev/sda2 contains the rootfs (a squashfs) and the rootfs data overlay
#    (a ext4 at the offset that can be seen by running losetup /dev/loop0).
# see https://openwrt.org/docs/guide-user/installation/openwrt_x86#partition_layout
opkg install parted losetup resize2fs
if [ -d /sys/firmware/efi ]; then
    opkg install sgdisk
    sgdisk --move-second-header /dev/sda
fi
parted --script /dev/sda resizepart 2 100%
losetup -c /dev/loop0
resize2fs /dev/loop0

# install useful packages.
opkg install qemu-ga
opkg install rsync
opkg install sfdisk lsblk
opkg install usbutils kmod-usb3 kmod-usb-storage-uas
opkg install pciutils

# delete all the network devices (e.g. br-lan).
while uci -q delete network.@device[0]; do :; done
uci commit

# customize the shell.
mkdir -p /etc/profile.d
cat >/etc/profile.d/login.sh <<'EOF'
export EDITOR=vim
export PAGER=less
alias l='ls -lF --color'
alias ll='l -a'
alias h='history 25'
alias j='jobs -l'
EOF

# delete the ssh keys.
rm -f /etc/dropbear/dropbear_*_host_key

# delete the package lists.
rm -rf /var/opkg-lists
