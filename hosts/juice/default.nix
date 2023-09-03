{...}: {
  imports = [
    ../hardware/raspi-v1.nix

    ./ntp.nix
    ./phone-vlan.nix
  ];

  networking.usePredictableInterfaceNames = false;

  system.stateVersion = "23.05";
}
