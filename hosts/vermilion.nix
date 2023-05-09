{
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./hardware/virt-v1.nix
  ];

  iliana.persist.home = true;

  users.users.iliana.packages = [
    pkgs.python3
    pkgs-unstable.actionlint
    pkgs-unstable.nodePackages.bash-language-server
    pkgs-unstable.nodePackages.yaml-language-server
    pkgs-unstable.python310Packages.python-lsp-server
    pkgs-unstable.rustup
  ];

  iliana.tailscale.tags = null;

  system.stateVersion = "22.11";
}
