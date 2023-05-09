{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  options = with lib; {
    iliana.dotfiles = mkOption {default = true;};
  };

  config = lib.mkIf config.iliana.dotfiles {
    system.activationScripts.ilianaDotfiles = {
      deps = ["users"];
      text = ''
        ${pkgs.sudo}/bin/sudo -H -u iliana ${pkgs.bash}/bin/bash ${../etc/dotfiles.sh} ${inputs.dotfiles.dotfiles}
      '';
    };
  };
}
