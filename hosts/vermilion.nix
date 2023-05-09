{
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./hardware/virt-v1.nix
  ];

  users.users.iliana.packages = [
    pkgs.python3
    pkgs-unstable.actionlint
    pkgs-unstable.nodePackages.bash-language-server
    pkgs-unstable.nodePackages.yaml-language-server
    pkgs-unstable.python310Packages.python-lsp-server
    pkgs-unstable.rustup
  ];

  iliana.persist.directories = [
    {
      directory = "/home/iliana";
      user = "iliana";
      group = "users";
      mode = "0700";
    }
  ];
  # Since this is a dev host and ~iliana is persisted, let dotfiles be mutable.
  iliana.dotfiles = false;
  iliana.tailscale.tags = null;

  system.stateVersion = "22.11";
}
