#!/bin/bash
set -euxo pipefail

vm_name=${1:-openwrt}; shift || true
interface_name=${1:-eth1}; shift || true
capture_filter=${1:-not port 22 and not port 3000 and not port 3100 and not 4000 and not port 16992 and not port 16994}; shift || true

mkdir -p tmp
vagrant ssh-config $vm_name >tmp/$vm_name-ssh-config.conf
wireshark -o "gui.window_title:$vm_name $interface_name" -k -i <(ssh -F tmp/$vm_name-ssh-config.conf $vm_name "tcpdump -s 0 -U -n -i $interface_name -w - $capture_filter")
