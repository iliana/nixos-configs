{
  config,
  lib,
  myPkgs,
  pkgs,
  ...
}: let
  localHost = "${config.networking.hostName}.cat-herring.ts.net";
  networks = {
    wobscale = {
      # wobscale IRC does not yet support SASL EXTERNAL, but authenticates with client certs fine
      client-cert = ./wobscale.pem.enc;
      host = "irc.wobscale.website";
      join = ./join-wobscale.conf.enc;
      local-port = 6697;
    };
    libera = {
      client-cert = ./libera.pem.enc;
      host = "irc.libera.chat";
      join = ./join-libera.conf.enc;
      local-port = 6698;
      sasl-external = true;
    };
  };
  users = ["pounce" "litterbox"];
  homes = lib.genAttrs users (name: "/var/lib/${name}");
in {
  systemd.services = let
    toINI = attrs:
      (builtins.concatStringsSep "\n"
        (lib.mapAttrsToList (k: v:
          if v == true
          then k
          else if builtins.isInt v
          then "${k} = ${toString v}"
          else "${k} = ${v}")
        attrs))
      + "\n";
    pounceServices = lib.mapAttrs' (network: attrs: let
      home = homes.pounce;
      encryptedAttrs = builtins.filter (attr: builtins.hasAttr attr attrs) ["client-cert"];
      cfg =
        {
          local-cert = config.iliana.tailscale.cert.certPath;
          local-host = localHost;
          local-priv = config.iliana.tailscale.cert.keyPath;
          nick = "iliana";
          palaver = true;
          save = "${home}/${network}.save";
        }
        // (builtins.removeAttrs attrs (encryptedAttrs ++ ["join"]));
      cfgFile = pkgs.writeText "pounce-${network}.conf" (toINI cfg);
    in
      lib.nameValuePair "pounce-${network}" {
        after = ["ts-cert.service"];
        requires = ["ts-cert.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig =
          config.iliana.systemd.sandboxConfig {
            denyTailscale = false;
            user = "pounce";
          }
          // {
            ExecStart =
              "${myPkgs.pounce}/bin/pounce ${cfgFile} \${CREDENTIALS_DIRECTORY}/join "
              + builtins.concatStringsSep " " (builtins.map (k: "--${k} \${CREDENTIALS_DIRECTORY}/${k}") encryptedAttrs);
            LoadCredentialEncrypted =
              (builtins.map (k: "${k}:${attrs.${k}}") encryptedAttrs)
              ++ ["join:/etc/pounce/join-${network}.txt.enc"];
            ReadWritePaths = home;
            Restart = "on-failure";
          };
      })
    networks;
    litterboxServices = lib.mapAttrs' (network: attrs: let
      home = homes.litterbox;
      cfg = {
        inherit network;
        database = "${home}/${network}.db";
        host = localHost;
        port = attrs.local-port;
        private-query = true;
        user = "litterbox";
      };
      cfgFile = pkgs.writeText "litterbox-${network}.conf" (toINI cfg);
    in
      lib.nameValuePair "litterbox-${network}" {
        after = ["pounce-${network}.service"];
        requires = ["pounce-${network}.service"];
        wantedBy = ["multi-user.target"];
        preStart = ''
          [[ -f ${cfg.database} ]] || ${myPkgs.litterbox}/bin/litterbox -i -d ${cfg.database}
        '';
        serviceConfig =
          config.iliana.systemd.sandboxConfig {
            denyTailscale = false;
            user = "litterbox";
          }
          // {
            ExecStart = "${myPkgs.litterbox}/bin/litterbox ${cfgFile}";
            ExecStartPost = "+${pkgs.acl}/bin/setfacl --remove-all --modify u:iliana:r ${cfg.database}";
            ReadWritePaths = home;
            Restart = "on-failure";
          };
      })
    networks;
  in
    pounceServices // litterboxServices;

  # There's no need to bounce pounce whenever we update `join`, because we can also manually join
  # the new channels on any client. We symlink networks.${network}.join into /etc and use that path
  # in the systemd unit to avoid restarts.
  environment.etc =
    lib.mapAttrs'
    (network: attrs:
      lib.nameValuePair "pounce/join-${network}.txt.enc" {
        source = attrs.join;
      })
    networks;

  users.users =
    lib.genAttrs users (name: {
      home = homes.${name};
      group = "${name}";
      isSystemUser = true;
    })
    // {
      iliana.packages = [myPkgs.litterbox];
    };
  users.groups = lib.genAttrs users (name: {});
  iliana.persist.directories =
    builtins.map (name: {
      directory = homes.${name};
      user = name;
      group = name;
    })
    users;

  iliana.tailscale.cert.enable = true;
  iliana.tailscale.cert.users = ["pounce"];
}
