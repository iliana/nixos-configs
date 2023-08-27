{transmission_4}:
transmission_4.overrideAttrs (old: {
  patches = [
    ./5460.patch
    ./5619.patch
    ./5644.patch
    ./5645.patch
  ];
})
