{pkgs-unstable, ...}: {
  imports = [
    ./hardware/virt-v1.nix
  ];

  users.users.iliana.packages = [
    pkgs-unstable.actionlint
    pkgs-unstable.nodePackages.bash-language-server
    pkgs-unstable.nodePackages.yaml-language-server
    pkgs-unstable.python310Packages.python-lsp-server
  ];

  system.stateVersion = "22.11";
}
