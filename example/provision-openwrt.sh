#!/bin/ash
set -euxo pipefail

CONFIG_LAN_IP="$1"
CONFIG_LAN_NETMASK="$2"

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
