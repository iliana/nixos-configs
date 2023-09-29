{pkgs, ...}: {
  iliana.dotfiles = false;
  iliana.persist.directories = [
    {
      directory = "/home/iliana";
      user = "iliana";
      group = "users";
      mode = "0700";
    }
  ];
  iliana.tailscale.acceptRoutes = true;
  iliana.tailscale.advertiseServerTag = false;
  iliana.tailscale.ssh = true;
  iliana.tailscale.policy.ssh = [
    {
      action = "accept";
      src = ["iliana@github"];
      dst = ["iliana@github"];
      users = ["iliana"];
    }
  ];

  users.users.iliana.packages = with pkgs; [
    actionlint
    black
    cachix
    dig
    gcc
    git
    go
    gopls
    grab-site
    isort
    moreutils
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
