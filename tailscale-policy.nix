let
  base = {
    acls = [
      {
        action = "accept";
        src = ["iliana@github"];
        proto = ["tcp" "udp"];
        dst = [
          "iliana@github:*"
          "autogroup:internet:*"
          "100.111.252.113:*"
        ];
      }
      {
        action = "accept";
        src = ["iliana@github"];
        proto = "tcp";
        dst = [
          "tag:home-assistant:80"
          "tag:server:22"
        ];
      }
      {
        action = "accept";
        src = ["autogroup:shared"];
        proto = "tcp";
        dst = ["100.113.241.94:22"];
      }
      {
        action = "accept";
        src = ["tag:tartarus"];
        proto = ["tcp" "udp"];
        dst = ["100.64.31.59:*"];
      }

      # temporary nyoom->woomy shenanigans
      {
        action = "accept";
        src = ["100.108.35.69"];
        proto = "tcp";
        dst = ["100.110.112.4:22"];
      }

      # Development Oxide control plane on onerous-tooth, via subnet router
      {
        action = "accept";
        src = ["iliana@github"];
        proto = ["tcp" "udp"];
        dst = [
          "192.168.1.0/24:*"
        ];
      }
      # DNS resolution for Oxide control plane (needs to be allowed for any exit
      # node, because DNS queries are forwarded to the exit node)
      {
        action = "accept";
        src = ["*"];
        proto = ["tcp" "udp"];
        dst = ["192.168.1.20:53" "192.168.1.21:53"];
      }
    ];

    ssh = [];

    tags = [
      "tag:home-assistant"
      "tag:server"
      "tag:tartarus"
    ];
  };

  inherit (import ./default.nix) sources hosts;
  configs =
    [
      (import (sources.nixpkgs + "/nixos/lib/eval-config.nix") {
        modules = [
          ./modules/base/policy.nix
          {iliana.tailscale.policy = base;}
        ];
      })
    ]
    ++ builtins.attrValues hosts;
  combinedPolicy = builtins.mapAttrs (attr: _: builtins.concatMap (system: system.config.iliana.tailscale.policy.${attr}) configs) base;
in {
  inherit (combinedPolicy) ssh;
  acls =
    builtins.map
    (acl:
      if acl.proto == ["tcp" "udp"]
      then builtins.removeAttrs acl ["proto"]
      else acl)
    combinedPolicy.acls;
  hosts = builtins.fromJSON (builtins.readFile ./modules/base/hosts.json);
  tagOwners = builtins.listToAttrs (builtins.map (name: {
      inherit name;
      value = ["iliana@github"];
    })
    combinedPolicy.tags);
  tests = [
    {
      user = "iliana@github";
      allow = ["iliana@github:1312" "alecto:53" "1.1.1.1:443" "172.20.3.69:22"];
    }
    {
      user = "tag:server";
      allow = ["alecto:53"];
      deny = ["iliana@github:22" "tag:server:22" "1.1.1.1:443" "172.20.3.69:22"];
    }
  ];
}
