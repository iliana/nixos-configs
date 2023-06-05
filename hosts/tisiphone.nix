{...}: {
  imports = [
    ./hardware/virt-v1.nix
  ];

  iliana.hardware.useSerialConsole = false;

  iliana.buildHost = true;
  iliana.pdns.enable = true;

  system.stateVersion = "23.05";
}
