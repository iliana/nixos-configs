{
  config,
  lib,
  ...
}: {
  imports = [
    ../hardware/virt-v1.nix

    ./20020-bot.nix
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

  iliana.backup = {
    enable = true;
    creds = ./backup;
  };

  system.stateVersion = "22.11";
}
