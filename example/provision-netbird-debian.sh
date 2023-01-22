#!/bin/bash
set -euxo pipefail

# see https://github.com/messense/openwrt-netbird/releases
version="${NETBIRD_VERSION:-0.12.0}"

# install.
# NB to configure netbird, you still need to connect from the ui or
#    execute sudo netbird up.
# see https://github.com/netbirdio/netbird
# see https://app.netbird.io/add-peer
apt-get install --no-install-recommends -y gpg
wget -qO- https://pkgs.wiretrustee.com/debian/public.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/wiretrustee.gpg
echo 'deb https://pkgs.wiretrustee.com/debian stable main' >/etc/apt/sources.list.d/wiretrustee.list
apt-get update
apt-get install -y netbird

# install the wireguard tools.
# NB this is not strictly required, but it allows us to use the wg
#    command to further inspect things.
apt-get install -y wireguard-tools

# configure and start netbird.
if [ -n "$NETBIRD_SETUP_KEY" ]; then
    netbird login --setup-key "$NETBIRD_SETUP_KEY"
    netbird up
    "$SHELL" -c 'while [ -z "$(netbird status)" ]; do sleep 3; done' # wait for being up.
    netbird status --detail
    wg show
else
    cat <<'EOF'
# WARNING
# WARNING since you did not provide the NETBIRD_SETUP_KEY environment variable
# WARNING netbird was not configured. you have to configure it manually using:
# WARNING
# WARNING   netbird up
# WARNING
EOF
fi
