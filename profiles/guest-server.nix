{ config, lib, pkgs, modulesPath, ... }: {
  imports = [
    ./tailscale.nix
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  environment.systemPackages = with pkgs; [
    fd
    git
    helix
    htop
    jq
    ripgrep
  ];
  programs.command-not-found.enable = false;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.chrony.enable = true;

  users.users.iliana = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
  security.sudo.wheelNeedsPassword = false;

  system.autoUpgrade = {
    enable = true;
    flags = [ "--update-input" "iliana" ];
    flake = "''";
  };

  boot.growPartition = true;
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [ "discard" ];
    autoResize = true;
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };
  services.fstrim.enable = true;
  zramSwap.enable = true;

  boot.loader.grub = {
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.loader.timeout = 0;
  boot.kernelParams = [ "console=ttyS0,115200n8" ];

  system.build.rawEfiImage = import (modulesPath + "/../lib/make-disk-image.nix") {
    inherit lib config pkgs;
    diskSize = 2048;
    format = "raw";
    partitionTableType = "efi";
  };
}
