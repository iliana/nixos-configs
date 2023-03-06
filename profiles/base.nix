{ config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    helix
    htop
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users.iliana = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
  security.sudo.wheelNeedsPassword = false;
}
