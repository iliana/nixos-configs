# shellcheck shell=bash
set -euo pipefail

cd "$(mktemp -d /srv/bind/zones.XXXXXXXXXX)"
chmod 0755 .
tar x

for zone in *.zone; do
    cat >>named.conf <<EOF
zone "${zone%.zone}" IN {
    type master;
    file "$PWD/$zone";
};
EOF
done

# We don't use bind-dnssec-db in production, but this is to work around
# https://github.com/PowerDNS/pdns/issues/8184#issuecomment-520047631
cat >pdns.conf <<EOF
launch=bind
bind-config=$PWD/named.conf
bind-dnssec-db=$PWD/dnssec.sqlite
EOF
pdnsutil --config-dir "$PWD" create-bind-db dnssec.sqlite
cp dnssec.sqlite{,.orig}
pdnsutil --config-dir "$PWD" check-all-zones
cmp <(sqlite3 dnssec.sqlite.orig .dump) <(sqlite3 dnssec.sqlite .dump)
rm pdns.conf dnssec.sqlite{,.orig}

ln -sf "$(basename "$PWD")/named.conf" /srv/bind/
sudo -u pdns pdns_control rediscover

find /srv/bind \
    -not -path "$PWD" \
    -not -path "$PWD/*" \
    -not -path /srv/bind \
    -not -path /srv/bind/named.conf \
    -delete
