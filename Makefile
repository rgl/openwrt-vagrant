SHELL=bash
.SHELLFLAGS=-euo pipefail -c
VERSION=24.10
IMG_URL='https://downloads.openwrt.org/releases/24.10.2/targets/x86/64/openwrt-24.10.2-x86-64-generic-squashfs-combined.img.gz'
IMG_SHA='2bceffbdba4563374ae7412553b1c8b8c5394225dc38fbf3c6a33a4649811158'
IMG_UEFI_URL='https://downloads.openwrt.org/releases/24.10.2/targets/x86/64/openwrt-24.10.2-x86-64-generic-squashfs-combined-efi.img.gz'
IMG_UEFI_SHA='2655edae580253bc08c269768fbead9f1f2fc4438da891c6af471724eab335cf'
IMG="tmp/$(basename $(notdir ${IMG_URL}))"
IMG_UEFI="tmp/$(basename $(notdir ${IMG_UEFI_URL}))"

help:
	@echo to build, type one of:
	@echo	make build-libvirt
	@echo	make build-uefi-libvirt

build-libvirt: openwrt-${VERSION}-amd64-libvirt.box
build-uefi-libvirt: openwrt-${VERSION}-uefi-amd64-libvirt.box

${IMG}:
	./img-download.sh ${IMG_URL} ${IMG_SHA} $@

${IMG_UEFI}:
	./img-download.sh ${IMG_UEFI_URL} ${IMG_UEFI_SHA} $@

openwrt-${VERSION}-amd64-libvirt.box: ${IMG} provision.sh openwrt.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.init.log \
		packer init openwrt.pkr.hcl
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log PKR_VAR_vagrant_box=$@ \
	PKR_VAR_img_url=${IMG} PKR_VAR_img_checksum=none \
		packer build -only=qemu.openwrt-amd64 -on-error=abort -timestamp-ui openwrt.pkr.hcl
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f openwrt-${VERSION}-amd64 $@

openwrt-${VERSION}-uefi-amd64-libvirt.box: ${IMG_UEFI} provision.sh openwrt.pkr.hcl Vagrantfile-uefi.template
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.init.log \
		packer init openwrt.pkr.hcl
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log PKR_VAR_vagrant_box=$@ \
	PKR_VAR_img_url=${IMG_UEFI} PKR_VAR_img_checksum=none \
		packer build -only=qemu.openwrt-uefi-amd64 -on-error=abort -timestamp-ui openwrt.pkr.hcl
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f openwrt-${VERSION}-uefi-amd64 $@

.PHONY: help buid-libvirt buid-uefi-libvirt
