{ ... }: {
  imports = [
    ../hardware/virt-v1.nix
  ];

  iliana.pdns.enable = true;

  system.stateVersion = "22.11";
}
