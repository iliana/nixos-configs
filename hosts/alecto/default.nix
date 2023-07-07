{...}: {
  imports = [
    ../hardware/virt-v1.nix
    ./irc.nix
  ];

  iliana.pdns.enable = true;

  iliana.hardware.biosBootDevice = "/dev/sda";
  iliana.hardware.useSerialConsole = false;
  networking.usePredictableInterfaceNames = false;
  networking.interfaces.eth0.ipv6.addresses = [
    {
      address = "2a01:4ff:1f0:c2de::1";
      prefixLength = 64;
    }
  ];
  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "eth0";
  };

  iliana.backup = {
    enable = true;
    creds = ./backup;
  };

  system.stateVersion = "23.05";
}
