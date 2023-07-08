{
  myPkgs,
  pkgs,
  ...
}: {
  imports = [
    ../hardware/virt-v1.nix
  ];

  users.users.iliana.packages = [
    myPkgs.oxide
    pkgs.actionlint
    pkgs.black
    pkgs.cachix
    pkgs.git
    pkgs.grab-site
    pkgs.isort
    pkgs.nil
    pkgs.nodePackages.bash-language-server
    pkgs.nodePackages.yaml-language-server
    pkgs.nvd
    pkgs.openssl
    pkgs.pylint
    pkgs.python3
    pkgs.python3Packages.python-lsp-server
    pkgs.rustup
    pkgs.shellcheck
    pkgs.tokei
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
  iliana.tailscale.acceptRoutes = true;

  iliana.backup.enable = true;
  iliana.backup.creds = ./backup;

  system.stateVersion = "22.11";
}
