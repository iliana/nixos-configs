{...}: {
  imports = [
    ./hardware/virt-v1.nix
  ];

  iliana.buildHost = true;

  system.stateVersion = "22.11";
}
