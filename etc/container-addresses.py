import hashlib
import ipaddress
import itertools
import json
import os

IPV4_BASE = ipaddress.ip_address("172.26.0.0")  # /15
IPV6_BASE = ipaddress.ip_address("fd3b:9df7:c407::")  # /48

hashes = {}
names = sorted(os.environ["names"].split())
for name in names:
    for i in itertools.count():
        digest = hashlib.sha256(f"{name}\x00{i}".encode("utf-8")).digest()
        h = int.from_bytes(digest[:2], byteorder="big")
        if h not in hashes:
            hashes[h] = name
            break
out = {}
for (h, name) in hashes.items():
    out[name] = {
        "hostAddress": str(IPV4_BASE + (h << 1)),
        "localAddress": str(IPV4_BASE + (h << 1) + 1),
        "hostAddress6": str(IPV6_BASE + (h << 64) + 1),
        "localAddress6": str(IPV6_BASE + (h << 64) + 2),
    }
with open(os.environ["out"], "w") as f:
    json.dump(out, f)
