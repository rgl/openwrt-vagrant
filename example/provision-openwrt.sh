#!/bin/ash
set -euxo pipefail

CONFIG_LAN_IP="$1"
CONFIG_LAN_NETMASK="$2"
CONFIG_DEBIAN_MAC="$3"
CONFIG_DEBIAN_IP="$4"

# update the package cache.
opkg update

# configure the network.
uci batch <<EOF
set network.wan=interface
set network.wan.ifname=eth1
set network.wan.proto=dhcp
set network.lan=interface
set network.lan.ifname=eth2
set network.lan.proto=static
set network.lan.ipaddr=$CONFIG_LAN_IP
set network.lan.netmask=$CONFIG_LAN_NETMASK
EOF
uci commit
service network reload

# configure static leases.
while uci -q delete dhcp.@host[0]; do :; done
id="$(uci add dhcp host)"
uci set "dhcp.$id.mac=$CONFIG_DEBIAN_MAC"
uci set "dhcp.$id.ip=$CONFIG_DEBIAN_IP"
uci commit dhcp

# install tcpdump.
opkg install tcpdump
