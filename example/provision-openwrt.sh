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

# wait until the network is configured.
while [ -z "$(ip addr show dev eth1 | grep -E ' inet \d+(\.\d+)+/')" ]; do sleep 5; done
CONFIG_LAN_IP_RE="$(echo "$CONFIG_LAN_IP" | sed -E 's,([.]),\\\1,g')"
while [ -z "$(ip addr show dev eth2 | grep -E " inet $CONFIG_LAN_IP_RE/")" ]; do sleep 5; done

# configure doh (dns over https).
# NB this configures dnsmasq to proxy requests to the local https-dns-proxy
#    service(s), which in turn will use doh to resolve the requests.
# see https://en.wikipedia.org/wiki/DNS_over_HTTPS
# see https://openwrt.org/docs/guide-user/services/dns/doh_dnsmasq_https-dns-proxy
# see https://openwrt.org/packages/pkgdata/https-dns-proxy
# see https://docs.openwrt.melmac.net/https-dns-proxy/
# see https://github.com/aarond10/https_dns_proxy
# see https://support.mozilla.org/en-US/kb/canary-domain-use-application-dnsnet
# see http://10.0.20.254/cgi-bin/luci/admin/network/dhcp
# see http://10.0.20.254/cgi-bin/luci/admin/services/https-dns-proxy
opkg install bind-dig
opkg install https-dns-proxy
opkg install luci-app-https-dns-proxy && service rpcd restart
# delete the existing configuration.
while uci -q delete https-dns-proxy.@https-dns-proxy[0]; do :; done
# add google.
# see https://developers.google.com/speed/public-dns/docs/using
id="$(uci add https-dns-proxy https-dns-proxy)"
uci set "https-dns-proxy.$id.bootstrap_dns=8.8.8.8,8.8.4.4"
uci set "https-dns-proxy.$id.resolver_url=https://dns.google/dns-query"
# add cloudflare.
# see https://developers.cloudflare.com/1.1.1.1/setup/router/
id="$(uci add https-dns-proxy https-dns-proxy)"
uci set "https-dns-proxy.$id.bootstrap_dns=1.1.1.1,1.0.0.1"
uci set "https-dns-proxy.$id.resolver_url=https://cloudflare-dns.com/dns-query"
# add quad9.
# see https://www.quad9.net/service/service-addresses-and-features#rec
id="$(uci add https-dns-proxy https-dns-proxy)"
uci set "https-dns-proxy.$id.bootstrap_dns=9.9.9.9,149.112.112.112"
uci set "https-dns-proxy.$id.resolver_url=https://dns.quad9.net/dns-query"
uci commit https-dns-proxy
service https-dns-proxy restart

# wait until names can be resolved.
while [ -z "$(dig +short debian.org @127.0.0.1 -p 5053)" ]; do sleep 5; done
while [ -z "$(dig +short debian.org)" ]; do sleep 5; done

# configure ad blocking.
# see https://openwrt.org/docs/guide-user/services/ad-blocking
# see https://openwrt.org/packages/pkgdata/adblock
# see https://github.com/openwrt/packages/tree/openwrt-22.03/net/adblock
opkg install adblock luci-app-adblock && service rpcd restart

# wait until adblock is ready.
while [ -z "$(service adblock status | grep -E 'adblock_status\s*:\s*enabled')" ]; do sleep 5; done

# configure static leases.
while uci -q delete dhcp.@host[0]; do :; done
id="$(uci add dhcp host)"
uci set "dhcp.$id.mac=$CONFIG_DEBIAN_MAC"
uci set "dhcp.$id.ip=$CONFIG_DEBIAN_IP"
uci commit dhcp

# install tcpdump.
opkg install tcpdump
