{...}: {
  imports = [
    ./hardware/virt-v1.nix
  ];

  iliana.hardware.useSerialConsole = false;
  networking.usePredictableInterfaceNames = false;
  networking.interfaces.eth0.ipv6.addresses = [
    {
      address = "2a01:4f8:c17:f980::1";
      prefixLength = 64;
    }
  ];
  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "eth0";
  };

  iliana.buildHost = true;
  iliana.pdns.enable = true;

  system.stateVersion = "23.05";
}
