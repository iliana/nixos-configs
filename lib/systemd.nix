{lib, ...}: {
  options = {
    iliana.systemd.sandboxConfig = lib.mkOption {
      readOnly = true;
      default = {denyTailscale ? true}: {
        CapabilityBoundingSet = "";
        DynamicUser = true;
        IPAddressAllow = lib.mkIf denyTailscale ["100.100.100.100"];
        IPAddressDeny = ["link-local" "multicast"] ++ lib.lists.optionals denyTailscale ["100.64.0.0/10"];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
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
    };
  };
}
