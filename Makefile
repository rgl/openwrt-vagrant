SHELL=bash
.SHELLFLAGS=-euo pipefail -c
VERSION=23.05
IMG_URL='https://downloads.openwrt.org/releases/23.05.0/targets/x86/64/openwrt-23.05.0-x86-64-generic-squashfs-combined.img.gz'
IMG_SHA='42d7eef88c08cef6605df0c0e4ac1b3749bf8376ef8717c332cf323dd89fc55c'
IMG_UEFI_URL='https://downloads.openwrt.org/releases/23.05.0/targets/x86/64/openwrt-23.05.0-x86-64-generic-squashfs-combined-efi.img.gz'
IMG_UEFI_SHA='e927ceb51e8750d03abb0170741b2473e369e4b458b7847d2fdb4331647a4c7e'
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
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log PKR_VAR_vagrant_box=$@ \
	PKR_VAR_img_url=${IMG} PKR_VAR_img_checksum=none \
		packer build -only=qemu.openwrt-amd64 -on-error=abort -timestamp-ui openwrt.pkr.hcl
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f openwrt-${VERSION}-amd64 $@

openwrt-${VERSION}-uefi-amd64-libvirt.box: ${IMG_UEFI} provision.sh openwrt.pkr.hcl Vagrantfile-uefi.template
	rm -f $@
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log PKR_VAR_vagrant_box=$@ \
	PKR_VAR_img_url=${IMG_UEFI} PKR_VAR_img_checksum=none \
		packer build -only=qemu.openwrt-uefi-amd64 -on-error=abort -timestamp-ui openwrt.pkr.hcl
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f openwrt-${VERSION}-uefi-amd64 $@

.PHONY: help buid-libvirt buid-uefi-libvirt
