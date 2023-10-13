#!/bin/ash
set -euxo pipefail

# install the wireguard tools.
# NB this is not strictly required, but it allows us to use the wg
#    command to further inspect things.
opkg install wireguard-tools

# install.
opkg install netbird

# configure and start netbird.
if [ -n "$NETBIRD_SETUP_KEY" ]; then
    netbird login --setup-key "$NETBIRD_SETUP_KEY"
    /etc/init.d/netbird enable
    /etc/init.d/netbird start
    /etc/init.d/netbird info
    /etc/init.d/netbird status
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
