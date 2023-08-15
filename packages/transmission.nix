{transmission_4}:
transmission_4.overrideAttrs (old: {
  patches = [
    ./transmission-5460.patch
    ./transmission-5619.patch
    ./transmission-5644.patch
    ./transmission-5645.patch
  ];
})
