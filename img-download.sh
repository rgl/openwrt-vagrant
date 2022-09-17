#!/bin/bash
set -euxo pipefail

url="$1"
sha="$2"
dst="$3"

# bail when it already exists.
if [ -f "$dst" ]; then
    exit 0
fi

# ensure the parent directory exists and the tmp file does not.
mkdir -p "$(dirname "$dst")"
rm -f "$dst.tmp.gz"

# download and verify the checksum.
wget -qO "$dst.tmp.gz" "$url"
echo "$sha $dst.tmp.gz" | sha256sum --check --status

# decompress and move to the final destination.
rm -f "$dst.tmp"
gunzip -q "$dst.tmp.gz" || true
mv "$dst.tmp" "$dst"
