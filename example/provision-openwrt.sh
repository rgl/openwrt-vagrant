#!/bin/ash
set -euxo pipefail

CONFIG_LAN_IP="$1"
CONFIG_LAN_NETMASK="$2"
CONFIG_DEBIAN_MAC="$3"
CONFIG_DEBIAN_IP="$4"
CONFIG_UBUNTU_MAC="$5"
CONFIG_UBUNTU_IP="$6"
CONFIG_WINDOWS_MAC="$7"
CONFIG_WINDOWS_IP="$8"
CONFIG_USE_DNSMASQ='0' # 0: replace dnsmasq with odhcpd and unbound. 1: use dnsmasq.
CONFIG_DOMAIN="$(uci get system.@system[0].hostname | sed -E 's,[^.]+\.(.+),\1,')"

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

# install tcpdump.
opkg install tcpdump

# install dig.
opkg install bind-dig

# replace dnsmasq with odhcpd and unbound.
if [ "$CONFIG_USE_DNSMASQ" == '0' ]; then
# see https://openwrt.org/docs/guide-user/base-system/dhcp_configuration#replacing_dnsmasq_with_odhcpd_and_unbound
# see https://openwrt.org/docs/guide-user/services/dns/dot_unbound
# see https://openwrt.org/docs/techref/odhcpd
# see https://github.com/openwrt/packages/blob/master/net/unbound/files/README.md#config-unbound
# use odhcpd as the DHCP server.
opkg remove dnsmasq odhcpd-ipv6only
opkg install odhcpd
# NB with odhcpd, dhcp.lan.domain sets the DHCP option 119 (Domain Search / DNS
#    domain search list). this behaviour is different than with dnsmasq, which
#    sets the DHCP option 15 (Domain Name / The DNS domain name of the client).
# NB with odhcpd, there is no way to set the DHCP option 15 (Domain Name / The
#    DNS domain name of the client).
#    see https://github.com/openwrt/odhcpd/issues/19#issuecomment-187574460
#    see https://github.com/openwrt/odhcpd/issues/19#issuecomment-382432988
# NB its possible to disable the dnsmasq DNS server by setting its port to 0 and
#    still use the unbound DNS server.
#    see https://openwrt.org/docs/guide-user/base-system/dhcp_configuration#disabling_dns_role
# see option 119 at https://www.iana.org/assignments/bootp-dhcp-parameters/bootp-dhcp-parameters.xhtml
uci -q delete dhcp.lan.domain || true
uci add_list dhcp.lan.domain=$CONFIG_DOMAIN
uci -q delete dhcp.@dnsmasq[0]
uci set dhcp.lan.dhcpv4=server
uci set dhcp.odhcpd.maindhcp=1
uci commit dhcp
service odhcpd restart
# use unbound as the DNS server/resolver/forwarder.
opkg install unbound-control unbound-daemon
uci set unbound.ub_main.domain=$CONFIG_DOMAIN
uci set unbound.@unbound[0].add_local_fqdn=1
uci set unbound.@unbound[0].add_wan_fqdn=1
uci set unbound.@unbound[0].dhcp4_slaac6=1
uci set unbound.@unbound[0].dhcp_link=odhcpd
uci set unbound.@unbound[0].unbound_control=1
uci commit unbound
service unbound restart
uci set dhcp.odhcpd.leasetrigger=/usr/lib/unbound/odhcpd.sh
uci commit dhcp
service odhcpd restart
# install the unbound luci application (available in the Services, Recursive DNS menu).
opkg install luci-app-unbound && service rpcd restart
# configure DoT (DNS over TLS).
# see https://developers.cloudflare.com/1.1.1.1/encryption/dns-over-tls/
# NB if your local network is also using OpenWRT to Force Router DNS resolution,
#    DoT will not work, as DoT requests will probably be intercepted by the
#    existing OpenWRT instance; so you have to disable it there.
# NB only a single forward zone can be enabled. if you try to enable more than
#    one, it will be ignored as can be seen in the logs as:
#       error: duplicate forward zone . ignored.
#    for using other upstream resolvers, you have to delete the existing fwd
#    zones and manually configure them.
uci set unbound.fwd_google.enabled=0
uci set unbound.fwd_google.fallback=0
uci set unbound.fwd_cloudflare.enabled=1
uci set unbound.fwd_cloudflare.fallback=0
uci commit unbound
service unbound restart
# show status.
unbound-control status
fi

# use dnsmasq.
if [ "$CONFIG_USE_DNSMASQ" == '1' ]; then
# configure DoH (DNS over HTTPS).
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
# wait until names can be resolved from the first https-dns-proxy resolver (e.g. google).
while [ -z "$(dig +short debian.org @127.0.0.1 -p 5053)" ]; do sleep 5; done
fi

# wait until names can be resolved.
while [ -z "$(dig +short debian.org)" ]; do sleep 5; done

# configure ad blocking.
# see https://openwrt.org/docs/guide-user/services/ad-blocking
# see https://openwrt.org/packages/pkgdata/adblock
# see https://github.com/openwrt/packages/tree/openwrt-23.05/net/adblock
# see /etc/config/adblock
# see /tmp/dnsmasq.d/adb_list.overall (when using dnsmasq as the DNS forwarder)
# see /var/lib/unbound/adb_list.overall (when using unbound as the DNS forwarder)
opkg install adblock luci-app-adblock && service rpcd restart

# wait until adblock is ready.
while [ -z "$(service adblock status | grep -E 'adblock_status\s*:\s*enabled')" ]; do sleep 5; done

# configure adblock.
uci delete adblock.global.adb_sources
uci add_list adblock.global.adb_sources=adaway
uci add_list adblock.global.adb_sources=adguard
uci add_list adblock.global.adb_sources=disconnect
uci add_list adblock.global.adb_sources=stevenblack
uci add_list adblock.global.adb_sources=yoyo
# configure the stevenblack variants.
uci -q delete adblock.global.adb_stb_sources || true
uci add_list adblock.global.adb_stb_sources=hosts # standard.
# configure the allow list.
cat >/etc/adblock/adblock.whitelist <<'EOF'
# allow the twitter link shortening. my twitter addiction must go on...
# NB this is denied by the yoyo list.
t.co
# allow the ClickHouse project.
# see https://github.com/ClickHouse/ClickHouse
clickhouse.com
EOF
# configure the startup trigger.
uci set adblock.global.adb_trigger=wan
uci set adblock.global.adb_triggerdelay=15
# apply changes.
uci commit adblock
service adblock reload

# configure static leases.
while uci -q delete dhcp.@host[0]; do :; done
id="$(uci add dhcp host)"
uci set "dhcp.$id.name=debian"
uci set "dhcp.$id.dns=1"
uci set "dhcp.$id.mac=$CONFIG_DEBIAN_MAC"
uci set "dhcp.$id.ip=$CONFIG_DEBIAN_IP"
id="$(uci add dhcp host)"
uci set "dhcp.$id.name=ubuntu"
uci set "dhcp.$id.dns=1"
uci set "dhcp.$id.mac=$CONFIG_UBUNTU_MAC"
uci set "dhcp.$id.ip=$CONFIG_UBUNTU_IP"
id="$(uci add dhcp host)"
uci set "dhcp.$id.name=windows"
uci set "dhcp.$id.dns=1"
uci set "dhcp.$id.mac=$CONFIG_WINDOWS_MAC"
uci set "dhcp.$id.ip=$CONFIG_WINDOWS_IP"
uci commit dhcp
if [ "$CONFIG_USE_DNSMASQ" == '1' ]; then
service dnsmasq reload
else
service odhcpd reload
fi

# install diff utilities.
opkg install diffutils

# install the wake-on-lan ui (etherwake frontend).
opkg install luci-app-wol

# install the Attended Sysupgrade application.
# NB this will be available under the System, Attended Sysupgrade LuCI menu.
# see https://openwrt.org/docs/guide-user/installation/attended.sysupgrade
opkg install luci-app-attendedsysupgrade
uci set attendedsysupgrade.client.advanced_mode='1'
uci commit attendedsysupgrade
