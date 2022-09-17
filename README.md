# About

This creates a OpenWrt base virtual machine image.

OpenWrt is installed using Packer and Vagrant.

# Usage

Install [Packer](https://www.packer.io/) and [Vagrant](https://www.vagrantup.com/).

Create the base image:

```bash
make build-libvirt
```

Try it using Vagrant:

```bash
cd example
vagrant up --no-destroy-on-error --provider=libvirt
vagrant ssh
```

Try it using the [LuCI web interface](https://openwrt.org/docs/guide-user/luci/start) at the created machine address.

# Notes

* Be aware that the bootloader and the machine console can be accessed without password.
  * For more details see [Serial console password](https://oldwiki.archive.openwrt.org/doc/howto/serial.console.password).

# References

* [OpenWrt Documentation](https://openwrt.org/docs)
  * [UCI system](https://openwrt.org/docs/guide-user/base-system/uci)
  * [Opkg package manager](https://openwrt.org/docs/guide-user/additional-software/opkg)
  * [Partition layout](https://openwrt.org/docs/guide-user/installation/openwrt_x86#partition_layout)
* [Vagrant OpenWrt Guest Plugin](https://github.com/hashicorp/vagrant/tree/main/plugins/guests/openwrt)
