# shellcheck shell=bash
set -euo pipefail

cd "$(mktemp -d /srv/bind/zones.XXXXXXXXXX)"
chmod 0755 .
tar x

cat >catalog.invalid.zone <<'EOF'
@ SOA invalid. invalid. 1312 10000 2400 604800 900
@ NS invalid.
version TXT "2"
EOF

for zone in *.zone; do
    [[ $zone = "catalog.invalid.zone" ]] && continue
    echo "$(sha224sum <<<"$zone" | awk '{ print $1 }').zones PTR ${zone%.zone}." >>catalog.invalid.zone
    kzonecheck -v "$zone"
done
kzonecheck -v catalog.invalid.zone

ln -sfvT "$(basename "$PWD")" /srv/bind/zones
sudo -u knot knotc zone-reload

find /srv/bind \
    -not -path "$PWD" \
    -not -path "$PWD/*" \
    -not -path /srv/bind \
    -not -path /srv/bind/zones \
    -delete
