let
  sources =
    builtins.mapAttrs
    (_: source: source // {outPath = builtins.fetchTarball {inherit (source) url sha256;};})
    (builtins.fromJSON (builtins.readFile ./sources.json));

  overlay = pkgs: orig: {
    bandcamp-dl = pkgs.callPackage ./packages/bandcamp-dl.nix {};
    caddy = pkgs.callPackage (sources.nixpkgs-unstable + "/pkgs/servers/caddy") {};
    craneLib = import sources.crane {inherit pkgs;};
    litterbox = pkgs.callPackage ./packages/litterbox.nix {};
    pounce = pkgs.callPackage ./packages/pounce.nix {inherit (orig) pounce;};
    transmission = pkgs.callPackage ./packages/transmission {inherit (sources) nixpkgs-unstable;};
    weechat = pkgs.callPackage ./packages/weechat.nix {inherit (sources) nixpkgs-unstable;};
    yt-dlp = pkgs.callPackage ./packages/yt-dlp {inherit (orig) yt-dlp;};
  };

  pkgs = import sources.nixpkgs {overlays = [overlay];};
  inherit (pkgs.lib) recurseIntoAttrs;

  hosts = builtins.mapAttrs (import ./mkHost.nix {inherit overlay sources;}) {
    alecto = {
      imports = [
        ./hardware/hetzner-v1.nix
        ./modules/backup.nix
        ./modules/irc
        ./modules/knot
      ];
      iliana.hardware.ipv6Address = "2a01:4ff:1f0:c2de::1/64";
      system.stateVersion = "23.05";
    };
    hydrangea = {
      imports = [
        ./hardware/virt-v1.nix
        ./modules/backup.nix
        ./modules/www/hydrangea.nix
      ];
      iliana.hardware.ipv6Address = "2620:fc:c000::209/64";
      iliana.hardware.networkInterfaceName = "ens2";
      system.stateVersion = "22.11";
    };
    juice = {
      imports = [
        ./hardware/raspi-v1.nix
        ./modules/ntp-stratum1
        ./modules/phone-vlan
      ];
      system.stateVersion = "23.05";
    };
    lernie = {
      imports = [
        ./hardware/virt-v1.nix
        ./modules/buildHost.nix
      ];
      system.stateVersion = "22.11";
    };
    megaera = {
      imports = [
        ./hardware/virt-v1.nix
        ./modules/20020-bot
        ./modules/backup.nix
        ./modules/knot
        ./modules/swoomba
      ];
      iliana.hardware.ipv6Address = "2620:fc:c000::212/64";
      iliana.hardware.networkInterfaceName = "ens2";
      system.stateVersion = "22.11";
    };
    mocha = {
      imports = [
        ./hardware/virt-v1.nix
        ./modules/mocha
      ];
      system.stateVersion = "23.05";
    };
    poffertje = {
      imports = [
        ./hardware/virt-v1.nix
        ./modules/transmission.nix
        ./modules/virtfs-media.nix
      ];
      system.stateVersion = "23.05";
    };
    skyrabbit = {
      imports = [
        ./hardware/virt-v1.nix
        ./modules/backup.nix
        ./modules/www/skyrabbit.7x6.net
      ];
      iliana.hardware.ipv6Address = "2620:fc:c000::226/64";
      iliana.hardware.networkInterfaceName = "ens2";
      system.stateVersion = "23.05";
    };
    stroopwafel = {
      imports = [
        ./hardware/virt-v1.nix
        ./modules/media-sync-tools
        ./modules/scuttlebutt.nix
        ./modules/virtfs-media.nix
        ./modules/www/pancake.ili.fyi.nix
      ];
      system.stateVersion = "23.05";
    };
    tisiphone = {
      imports = [
        ./hardware/hetzner-v1.nix
        ./modules/buildHost.nix
        ./modules/knot
      ];
      iliana.hardware.ipv6Address = "2a01:4f8:c17:f980::1/64";
      nixpkgs.hostPlatform = "aarch64-linux";
      system.stateVersion = "23.05";
    };
    vermilion = {
      imports = [
        ./hardware/virt-v1.nix
        ./modules/backup.nix
        ./modules/dev.nix
      ];
      iliana.backup.exclude = ["/nix/persist/home/iliana/git/nixpkgs"];
      system.stateVersion = "22.11";
    };
  };

  tests = builtins.mapAttrs (import ./mkTest.nix {inherit hosts pkgs;}) {
    knot = import ./tests/knot.nix;
    web = import ./tests/web.nix;
  };
in {
  inherit sources pkgs hosts tests;
  ciJobs = recurseIntoAttrs {
    hosts = recurseIntoAttrs (builtins.mapAttrs (_: system: system.config.system.build.toplevel) hosts);
    tests = recurseIntoAttrs tests;
  };
  misc.tool-env = pkgs.python3.withPackages (ps: [ps.semver]);
}
