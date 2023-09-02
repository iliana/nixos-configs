{...}: {
  imports = [
    ../hardware/raspi-v1.nix

    ./ntp.nix
  ];

  system.stateVersion = "23.05";
}
