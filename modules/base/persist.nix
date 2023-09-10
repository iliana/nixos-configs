{
  config,
  lib,
  test,
  ...
}: let
  persistDir = "/nix/persist";
in {
  imports = [
    (lib.mkAliasOptionModule ["iliana" "persist"] ["environment" "persistence" persistDir])
  ];

  config = {
    system.activationScripts.createNixPersist.text = "[ -d ${persistDir} ] || mkdir ${persistDir}";
    system.activationScripts.createPersistentStorageDirs.deps = ["createNixPersist"];

    iliana.persist.hideMounts = true;
    iliana.persist.directories = [
      "/var/db/dhcpcd"
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/log"
      {
        directory = "/var/lib/chrony";
        user = "chrony";
        group = "chrony";
      }
    ];
    iliana.persist.files =
      [
        "/etc/machine-id"
      ]
      ++ lib.lists.optionals config.services.openssh.enable [
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];

    # Work around /var/lib/nixos and /var/log being "required for boot".
    #
    # These filesystems need to be mounted during the initrd, but in the NixOS
    # test environment, a blank disk is passed as /dev/vda and formatted as an
    # empty ext4 filesystem prior to mounts, and source devices for mounts must
    # exist or the initrd will fail.
    #
    # This script instead formats /dev/vda as a filesystem with the source
    # devices of the "required for boot" bind mounts. (It technically might get
    # merged into the script _before_ the built-in disk formatter, but that one
    # has a check to ensure there's no disk label present.)
    boot.initrd.postDeviceCommands = lib.mkIf test ''
      mkdir -p $targetRoot/nix/persist/var/lib/nixos
      mkdir -p $targetRoot/nix/persist/var/log
      mke2fs -t ext4 -d $targetRoot /dev/vda
      rm -rf $targetRoot
    '';
  };
}
