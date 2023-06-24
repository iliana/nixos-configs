{...}: {
  imports = [
    ./hardware/virt-v1.nix
  ];

  iliana.pdns.enable = true;

  networking.dhcpcd.IPv6rs = true;
  networking.interfaces.ens2.ipv6.addresses = [
    {
      address = "2620:fc:c000::212";
      prefixLength = 64;
    }
  ];

  system.stateVersion = "22.11";
}
