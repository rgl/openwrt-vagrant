SHELL=bash
.SHELLFLAGS=-euo pipefail -c
VERSION=22.03
IMG_URL='https://downloads.openwrt.org/releases/22.03.0/targets/x86/64/openwrt-22.03.0-x86-64-generic-squashfs-combined.img.gz'
IMG_SHA='c993a8c519b073966e90baedb6901cf5de2e5c9b78080b84edb72409f6a82551'
IMG="tmp/$(basename $(notdir ${IMG_URL}))"

help:
	@echo to build, type one of:
	@echo	make build-libvirt

build-libvirt: openwrt-${VERSION}-amd64-libvirt.box

${IMG}:
	./img-download.sh ${IMG_URL} ${IMG_SHA} $@

${IMG_UEFI}:
	./img-download.sh ${IMG_UEFI_URL} ${IMG_UEFI_SHA} $@

openwrt-${VERSION}-amd64-libvirt.box: ${IMG} provision.sh openwrt.pkr.hcl Vagrantfile.template
	rm -f $@
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log PKR_VAR_vagrant_box=$@ \
	PKR_VAR_img_url=${IMG} PKR_VAR_img_checksum=none \
		packer build -only=qemu.openwrt-amd64 -on-error=abort -timestamp-ui openwrt.pkr.hcl
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f openwrt-${VERSION}-amd64 $@

.PHONY: help buid-libvirt
