{
  config,
  lib,
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
    iliana.persist.directories = lib.mkOrder 1500 [
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
  };
}
