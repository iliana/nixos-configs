{yt-dlp, ...}:
yt-dlp.overrideAttrs (old: {
  patches = [./8238.patch];
})
