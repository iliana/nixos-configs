{
  config,
  lib,
  pkgs,
  test,
}: {
  caddy = let
    serveWith = {
      index ? ["index.html"],
      passthru ? false,
    }: root: let
      matcher = "@exists${builtins.hashString "sha256" "${root}"}";
    in ''
      ${
        lib.optionalString (lib.hasPrefix builtins.storeDir root) ''
          ${matcher} file {
            root ${root}
            try_files {path} ${builtins.concatStringsSep " " (builtins.map (x: "{path}/${x}") index)}
          }
          header ${matcher} -last-modified
          header ${matcher} etag `"${builtins.substring (builtins.stringLength builtins.storeDir + 1) 32 root}"`
        ''
      }
      file_server {
        root ${root}
        index ${builtins.concatStringsSep " " index}
        ${lib.optionalString passthru "pass_thru"}
      }
    '';
  in {
    localhost = port: ''
      reverse_proxy localhost:${toString port}
    '';
    redirPrefix = prefix: ''
      redir ${prefix}{uri}
    '';
    requireTailscale = config: ''
      @external not remote_ip 100.64.0.0/10 127.0.0.0/24
      abort @external

      ${config}
    '';
    serve = serveWith {};
    inherit serveWith;
  };

  credentials = c:
    if test
    then {
      LoadCredential =
        lib.mapAttrsToList
        (name: value: "${name}:${pkgs.writeText name value.testValue}")
        c;
    }
    else {
      LoadCredentialEncrypted =
        lib.mapAttrsToList
        (name: value: "${name}:${value.encrypted}")
        c;
    };

  systemdSandbox = {
    denyTailscale ? true,
    user ? null,
  }: {
    IPAddressAllow = lib.mkIf denyTailscale ["100.100.100.100"];
    IPAddressDeny = ["link-local" "multicast"] ++ lib.lists.optionals denyTailscale ["100.64.0.0/10"];

    DynamicUser = lib.mkIf (user == null) true;
    User = lib.mkIf (user != null) user;
    Group = lib.mkIf (user != null) config.users.users.${user}.group;

    CapabilityBoundingSet = "";
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateTmp = true;
    PrivateUsers = true;
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHome = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectProc = "invisible";
    ProtectSystem = "strict";
    RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6";
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = ["@system-service" "~@resources @privileged"];
  };
}
