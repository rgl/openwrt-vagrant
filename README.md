# About

This creates a OpenWrt base virtual machine image.

OpenWrt is installed using Packer and Vagrant.

# Usage

Install:

* [Packer](https://www.packer.io/)
* [Vagrant](https://www.vagrantup.com/)
* [vagrant-libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt)
* [Debian 12 UEFI base image](https://github.com/rgl/debian-vagrant)
* [Ubuntu 22.04 UEFI base image](https://github.com/rgl/ubuntu-vagrant)
* [Windows 2022 UEFI base image](https://github.com/rgl/windows-vagrant)

Create the UEFI base image:

```bash
make build-uefi-libvirt
```

Start the example Vagrant environment:

```bash
cd example
# optionally set a netbird setup key to automatically configure netbird.
# see https://app.netbird.io/setup-keys
export NETBIRD_SETUP_KEY=""
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

Access the `ubuntu` virtual machine, which is connected to the OpenWrt `lan` network:

```bash
vagrant ssh ubuntu
# see the systemd-resolved status.
# NB when netbird is up, it should register itself as the DNS server for
#    the netbird.cloud domain in the wt0 interface.
#    see https://netbird.io/docs/how-to-guides/nameservers
resolvectl
# ping the debian machine using the netbird.cloud domain.
ping debian.netbird.cloud
```

Access the `windows` virtual machine, which is connected to the OpenWrt `lan` network:

```bash
vagrant ssh windows
# ping the debian machine using the netbird.cloud domain.
ping debian.netbird.cloud
```

## Network Packet Capture

You can easily capture and see traffic from the host with the `wireshark.sh`
script, e.g., to capture the traffic from the `eth1` (wan) interface:

```bash
# NB interfaces: eth1 (wan), eth2 (lan).
# NB ports: 53 (DNS), 853 (DoT), 443 (DoH).
./wireshark.sh openwrt eth1 'port 53 or port 853'
```

# Notes

* Be aware that the bootloader and the machine console can be accessed without password.
  * For more details see [Serial console password](https://oldwiki.archive.openwrt.org/doc/howto/serial.console.password).
* When using the Unbound DNS server, you can configure extra DNS zones.
  * Edit the `/etc/unbound/unbound_srv.conf` file from the terminal.
    * Or, edit it from the LuCI web interface:
      * Select the `Services > Recursive DNS` menu.
      * Select the `Files` tab.
      * Select the `Edit: Server` tab.
  * Append the zone content. e.g.:
    ```conf
    domain-insecure: example.test
    private-domain: example.test
    local-zone: example.test static
    local-data: "example.test. 7200 IN SOA localhost. nobody.invalid. 28400605 3600 1200 9600 300"
    local-data: "example.test. 7200 IN NS localhost."
    local-data: 'example.test. 7200 IN TXT "comment=local intranet dns zone"'
    local-data: "hello.example.test. 300 IN A 192.168.1.11"
    ```
  * Reload the service with `service unbound reload`.

# Commands

* `logread -e dnsmasq`
  * show the `dnsmasq` service logs.
* `logread -e unbound`
  * show the `unbound` service logs.
* `uci show`
  * show the configuration.
* `fw4 print`
  * show the firewall configuration.
* `nft list ruleset`
  * show the [nftables](https://wiki.archlinux.org/title/Nftables) rules.
* `opkg list-installed`
  * show the installed packages.
* `dig +short @v4.ident.me`
  * show the current public ipv4 address from the internet viewpoint (see https://api.ident.me/).
* `dig +short @v6.ident.me`
  * show the current public ipv6 address from the internet viewpoint (see https://api.ident.me/).

# References

* [OpenWrt Documentation](https://openwrt.org/docs)
  * [UCI system](https://openwrt.org/docs/guide-user/base-system/uci)
  * [Opkg package manager](https://openwrt.org/docs/guide-user/additional-software/opkg)
  * [OpenWrt on x86 hardware (PC / VM / server)](https://openwrt.org/docs/guide-user/installation/openwrt_x86)
  * [Partition layout](https://openwrt.org/docs/guide-user/installation/openwrt_x86#partition_layout)
* [Vagrant OpenWrt Guest Plugin](https://github.com/hashicorp/vagrant/tree/main/plugins/guests/openwrt)
