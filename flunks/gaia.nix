{
  buildEnv,
  buildGoModule,
  fetchFromGitHub,
  python3Packages,
  tailscale,
  writeShellApplication,
  writeTextDir,
}: let
  hosts = builtins.fromJSON (builtins.readFile ../modules/base/hosts.json);

  striped = buildGoModule {
    name = "striped";
    src = fetchFromGitHub {
      owner = "iliana";
      repo = "striped";
      rev = "78c88d85a6b7e3c6f0d2d4447854434963e727f9";
      hash = "sha256-aH6CrFRMRcP28gwWAOt4MKiVUKlv5NNpbh1CKY6Jye0=";
    };
    vendorHash = "sha256-3LJdx7h19fJPsujbamFRwSjDm4v97oGyGAv5yl4W0io=";
  };

  confstorepath = "etc/supervisord.conf";
  conf = writeTextDir confstorepath ''
    [unix_http_server]
    file = %(ENV_HOME)s/supervisor.sock

    [supervisord]
    logfile = %(ENV_HOME)s/supervisord.log
    pidfile = %(ENV_HOME)s/supervisord.pid

    [rpcinterface:supervisor]
    supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

    [supervisorctl]
    serverurl = unix://%(ENV_HOME)s/supervisor.sock

    [program:striped]
    command = ${striped}/bin/striped :17259 10.0.0.1:1055 ${hosts.poffertje}:17259
    autorestart = true
    redirect_stderr = true
    stdout_logfile = %(ENV_HOME)s/.striped.log

    [program:tailscaled]
    command = ${tailscale}/bin/tailscaled --socket %(ENV_HOME)s/.tailscaled.sock --tun=userspace-networking --socks5-server=10.0.0.1:1055
    autorestart = true
    redirect_stderr = true
    stdout_logfile = %(ENV_HOME)s/.local/share/tailscale/tailscaled.log
  '';
  confpath = "~/.local/share/nix/root/nix/var/nix/profiles/system/${confstorepath}";
in
  buildEnv {
    name = "flunk-gaia";
    paths = [
      (writeShellApplication {
        name = "activate";
        runtimeInputs = [python3Packages.supervisor];
        text = ''
          if supervisorctl -c ${confpath} pid &>/dev/null; then
            supervisorctl -c ${confpath} update
          else
            supervisord -c ${confpath}
          fi
        '';
      })
      (writeShellApplication {
        name = "cronscript";
        runtimeInputs = [python3Packages.supervisor];
        text = ''
          supervisorctl -c ${confpath} pid &>/dev/null || supervisord -c ${confpath}
        '';
      })
      (writeShellApplication {
        name = "supervisorctl";
        runtimeInputs = [python3Packages.supervisor];
        text = ''
          exec supervisorctl -c ${confpath} "$@"
        '';
      })
      conf
    ];
    meta.flunk = {
      binPath = "~/bin";
      tailscale.policy.acls = [
        {
          action = "accept";
          src = ["iliana@github"];
          proto = "tcp";
          dst = ["gaia:22"];
        }
      ];
      tailscale.policy.tags = ["tag:gaia"];
    };
  }
