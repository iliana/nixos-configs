{ config, lib, pkgs, ... }: {
  imports = [
    ../hardware/virt-v1.nix
  ];

  age.identityPaths = [ "/nix/persist/etc/ssh/ssh_host_ed25519_key" ];
  age.secrets.nix-cache.file = ../etc/nix-cache.age;
  age.secrets.hydra-github-auth = {
    file = ../etc/hydra-github-auth.age;
    mode = "0440";
    owner = "hydra";
    group = "hydra";
  };

  services.hydra = {
    enable = true;
    port = 3000;
    hydraURL = "http://${config.networking.hostName}.cat-herring.ts.net:${toString config.services.hydra.port}";
    notificationSender = "hydra@localhost";
    buildMachinesFiles = [ ];
    useSubstitutes = true;

    extraConfig = ''
      Include ${config.age.secrets.hydra-github-auth.path}

      <githubstatus>
        jobs = nixos-configs:main:.*
        excludeBuildFromContext = 1
        useShortContext = 1
      </githubstatus>
    '';
  };

  iliana.persist.directories = [
    {
      directory = "/var/lib/hydra";
      user = "hydra";
      group = "hydra";
      mode = "0750";
    }
    {
      directory = "/var/lib/postgresql";
      user = "postgres";
      group = "postgres";
      mode = "0750";
    }
  ];

  iliana.caddy.virtualHosts = with config.iliana.caddy.helpers; {
    "nix-cache.ili.fyi" = container "nix-serve" 5000;
  };

  iliana.containerNameservers = [ "8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844" ];
  iliana.containers = {
    nix-serve = {
      extraFlags = [ "--load-credential=NIX_SECRET_KEY_FILE:${config.age.secrets.nix-cache.path}" ];
      cfg = { config, ... }: {
        services.nix-serve = {
          enable = true;
          port = 5000;
          openFirewall = true;

          package = pkgs.nix-serve.overrideAttrs (_: {
            postPatch = ''
              # ensure what we're trying to replace actually exists
              grep -qF "Priority: 30" nix-serve.psgi

              substituteInPlace nix-serve.psgi --replace "Priority: 30" "Priority: 69"
            '';
          });

          # We aren't mounting the decrypted secret key into the container, but
          # instead propagating it through the container's service manager. To
          # get the service to set the NIX_SECRET_KEY_FILE environment variable
          # though this needs to be set to something.
          secretKeyFile = "/dev/null";
        };

        # Override `LoadCredential` to propagate from systemd-nspawn's
        # `--load-credential=`.
        systemd.services.nix-serve.serviceConfig.LoadCredential = lib.mkForce "NIX_SECRET_KEY_FILE";
      };
    };
  };

  system.stateVersion = "22.11";
}
