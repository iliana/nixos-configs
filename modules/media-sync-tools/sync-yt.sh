#!/usr/bin/env bash
set -euxo pipefail

while read -r dir url; do
    mkdir -p "/media/yt/$dir"
    cd "/media/yt/$dir"
    yt-dlp --compat-options no-youtube-unavailable-videos --download-archive /media/yt/_control/archive.txt "$url"
done </media/yt/_control/channels.txt
