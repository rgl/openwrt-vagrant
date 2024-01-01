#!/bin/bash
set -euxo pipefail

vm_name=${1:-openwrt}; shift || true
# interfaces: eth0 (vagrant/management), eth1 (wan), eth2 (lan).
interface_name=${1:-eth2}; shift || true
# ports: 22 (SSH).
capture_filter=${1:-not port 22}; shift || true

mkdir -p tmp
vagrant ssh-config $vm_name >tmp/$vm_name-ssh-config.conf
wireshark -o "gui.window_title:$vm_name $interface_name" -k -i <(ssh -F tmp/$vm_name-ssh-config.conf $vm_name "tcpdump -s 0 -U -n -i $interface_name -w - $capture_filter")
