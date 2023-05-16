{
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./hardware/virt-v1.nix
  ];

  users.users.iliana.packages = [
    pkgs.black
    pkgs.git
    pkgs.isort
    pkgs.nvd
    pkgs.pylint
    pkgs.python3
    pkgs.python3Packages.python-lsp-server
    pkgs-unstable.actionlint
    pkgs-unstable.nil
    pkgs-unstable.nodePackages.bash-language-server
    pkgs-unstable.nodePackages.yaml-language-server
    pkgs-unstable.rustup
    pkgs-unstable.shellcheck
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

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  system.stateVersion = "22.11";
}
