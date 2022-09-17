SHELL=bash
.SHELLFLAGS=-euo pipefail -c
VERSION=22.03
IMG_URL='https://downloads.openwrt.org/releases/22.03.0/targets/x86/64/openwrt-22.03.0-x86-64-generic-squashfs-combined.img.gz'
IMG_SHA='c993a8c519b073966e90baedb6901cf5de2e5c9b78080b84edb72409f6a82551'
IMG_UEFI_URL='https://downloads.openwrt.org/releases/22.03.0/targets/x86/64/openwrt-22.03.0-x86-64-generic-squashfs-combined-efi.img.gz'
IMG_UEFI_SHA='ee4a3d1576a12fd6663cdf5db7a3c3431be1327d4f5e3354435318997c104fad'
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
