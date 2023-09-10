{
  config,
  lib,
  pkgs,
  sources,
  ...
}: let
  # npins doesn't support submodules quite yet.
  dotfiles = builtins.fetchGit {
    url = "https://github.com/iliana/dotfiles.git";
    rev = sources.dotfiles.revision;
    submodules = true;
  };
  script = lib.getExe (pkgs.writeShellApplication {
    name = "sync-dotfiles";
    text = ''
      ln -sfn ${dotfiles} ~/.dotfiles
      cp -rsf --no-preserve=mode,ownership ~/.dotfiles/. ~
      # find broken links to ~/.dotfiles and delete them
      find ~ -lname ~/.dotfiles/'*' -xtype l -delete -print
    '';
  });
in {
  options = with lib; {
    iliana.dotfiles = mkOption {default = true;};
  };

  config = lib.mkIf config.iliana.dotfiles {
    system.activationScripts.ilianaDotfiles = {
      deps = ["users"];
      text = ''
        ${pkgs.sudo}/bin/sudo -H -u iliana ${script}
      '';
    };
  };
}
