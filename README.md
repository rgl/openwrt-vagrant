# About

This creates a OpenWrt base virtual machine image.

OpenWrt is installed using Packer and Vagrant.

# Usage

Install:

* [Packer](https://www.packer.io/)
* [Vagrant](https://www.vagrantup.com/)
* [Debian 11 base image](https://github.com/rgl/debian-vagrant)

Create the base image:

```bash
make build-libvirt
```

Start the example Vagrant environment:

```bash
cd example
vagrant up --no-destroy-on-error --provider=libvirt
```

Access the [LuCI web interface](https://openwrt.org/docs/guide-user/luci/start)
at the created machine address with the `root` user and the `vagrant` password:

http://10.0.20.254

Access the `openwrt` virtual machine:

```bash
vagrant ssh openwrt
```

Access the `debian` virtual machine, which is connected to the OpenWrt `lan` network:

```bash
vagrant ssh debian
```

# Notes

* Be aware that the bootloader and the machine console can be accessed without password.
  * For more details see [Serial console password](https://oldwiki.archive.openwrt.org/doc/howto/serial.console.password).

# Commands

* `logread -e dnsmasq`
  * show the `dnsmasq` service logs.
* `uci show`
  * show the configuration.
* `nft list ruleset`
  * show the [nftables](https://wiki.archlinux.org/title/Nftables) rules.

# References

* [OpenWrt Documentation](https://openwrt.org/docs)
  * [UCI system](https://openwrt.org/docs/guide-user/base-system/uci)
  * [Opkg package manager](https://openwrt.org/docs/guide-user/additional-software/opkg)
  * [Partition layout](https://openwrt.org/docs/guide-user/installation/openwrt_x86#partition_layout)
* [Vagrant OpenWrt Guest Plugin](https://github.com/hashicorp/vagrant/tree/main/plugins/guests/openwrt)
