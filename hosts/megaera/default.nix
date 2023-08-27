{
  config,
  lib,
  ...
}: {
  imports = [
    ../hardware/virt-v1.nix

    ./swoomba
  ];

  iliana.pdns.enable = true;

  networking.dhcpcd.IPv6rs = true;
  networking.interfaces.ens2 = lib.mkIf (!config.iliana.test) {
    ipv6.addresses = [
      {
        address = "2620:fc:c000::212";
        prefixLength = 64;
      }
    ];
  };

  system.stateVersion = "22.11";
}
