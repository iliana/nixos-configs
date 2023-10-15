{...}: {
  users.users.spiders = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM98VEYjUTozjyHRA6X1bkllY/rZ3qPbfUyIJ0HN/OTp"
    ];
  };
  services.openssh.openFirewall = true;
}
