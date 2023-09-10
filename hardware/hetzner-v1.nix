{
  config,
  lib,
  pkgs,
  test,
  ...
}: let
  cfg = config.iliana.hardware;
in {
  imports = [./virt-v1.nix];

  config = {
    iliana.hardware.biosBootDevice = lib.mkIf pkgs.stdenv.hostPlatform.isx86 "/dev/sda";
    iliana.hardware.serialConsole = "tty1";

    iliana.hardware.networkInterfaceName = "eth0";
    networking = lib.mkIf (!test) {
      dhcpcd.IPv6rs = null; # TODO: make this `false`
      defaultGateway6 = lib.mkIf (cfg.ipv6Address != null) {
        address = "fe80::1";
        interface = "eth0";
      };
      usePredictableInterfaceNames = false;
    };
  };
}
