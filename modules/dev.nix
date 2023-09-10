{
  lib,
  pkgs,
  ...
}: {
  iliana.dotfiles = false;
  iliana.persist.directories = lib.mkOrder 1300 [
    {
      directory = "/home/iliana";
      user = "iliana";
      group = "users";
      mode = "0700";
    }
  ];
  iliana.tailscale.acceptRoutes = true;
  iliana.tailscale.advertiseServerTag = false;

  users.users.iliana.packages = with pkgs; [
    oxide
    actionlint
    black
    cachix
    git
    go
    gopls
    grab-site
    isort
    nil
    nodePackages.bash-language-server
    nodePackages.yaml-language-server
    nvd
    openssl
    pylint
    python3
    python3Packages.python-lsp-server
    rustup
    shellcheck
    tokei
  ];
}
