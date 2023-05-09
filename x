#!/usr/bin/env bash
x="$(dirname "${BASH_SOURCE[0]}")/etc/x.py"
if command -v python3 >/dev/null 2>&1; then
    python3 "$x" "$@"
else
    nix run nixpkgs#python3 -- "$x" "$@"
fi
