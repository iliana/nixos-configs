{pkgs-unstable, ...}: {
  imports = [
    ./hardware/virt-v1.nix
  ];

  iliana.persist.home = true;

  users.users.iliana.packages = [
    pkgs-unstable.actionlint
    pkgs-unstable.nodePackages.bash-language-server
    pkgs-unstable.nodePackages.yaml-language-server
    pkgs-unstable.python310Packages.python-lsp-server
  ];

  iliana.tailscale.tags = null;

  system.stateVersion = "22.11";
}
