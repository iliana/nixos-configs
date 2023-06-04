{...}: {
  imports = [
    ./hardware/virt-v1.nix
  ];

  iliana.pdns.enable = true;

  iliana.hardware.biosBootDevice = "/dev/sda";
  iliana.hardware.useSerialConsole = false;
  system.stateVersion = "23.05";
}
