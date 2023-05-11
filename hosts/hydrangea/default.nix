{config, ...}: {
  imports = [
    ../hardware/virt-v1.nix

    ./emojos-dot-in.nix
    ./nitter.nix
    ./pkgf.nix
  ];

  iliana.caddy.virtualHosts = with config.iliana.caddy.helpers; {
    "haha.business" = serve ./haha.business;
  };

  iliana.containerNameservers = ["8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844"];
  networking.firewall.allowedTCPPorts = [80 443];

  system.stateVersion = "22.11";
}
