{
  hydrangea,
  skyrabbit,
  pkgs,
  ...
}: {
  nodes = {
    inherit hydrangea skyrabbit;
    testremote = {config, ...}: {
      services.caddy.enable = true;
      services.caddy.virtualHosts.":80".extraConfig = ''
        respond /asdf "thx"
      '';
      networking.firewall.allowedTCPPorts = [80];
    };
  };
  testScript = let
    pkgfPayload = pkgs.writeText "pkgf-payload.json" (builtins.toJSON {
      text = "You received ... pickup now.";
    });
  in ''
    import hashlib
    from urllib.parse import urlparse

    def fetch(url, f=hydrangea.wait_until_succeeds, extra=""):
        parsed = urlparse(url)
        port = 80 if parsed.scheme == "http" else 443
        cmd = f"curl -fks --resolve {parsed.hostname}:{port}:127.0.0.1 {url} {extra}"
        return f(cmd.strip(), timeout=15)

    start_all()

    hydrangea.wait_for_unit("caddy")
    fetch("https://hydrangea.ili.fyi/yo")
    fetch("https://haha.business")

    output = fetch("https://qalico.net/.well-known/matrix/client", extra="-o /dev/null -w '%header{access-control-allow-origin}'")
    assert output == "*"
    output = fetch("https://qalico.net/.well-known/matrix/client").encode("ascii")
    assert hashlib.sha256(output).hexdigest() == "11653f4a62f55f5596e5667359ff543af225d4283a66254294ce660d6074be50"
    output = fetch("https://qalico.net/.well-known/matrix/server").encode("ascii")
    assert hashlib.sha256(output).hexdigest() == "cec3f97ceaf928aec438da492ae723d3a8e6f856750f6adc5f51818e65ecab8b"

    hydrangea.wait_for_unit("pkgf")
    testremote.wait_for_unit("caddy")
    testremote.fail("[[ -f /var/log/caddy/access-:80.log ]]")
    fetch("https://hydrangea.ili.fyi/pkgf/test", f=hydrangea.fail)
    fetch("https://hydrangea.ili.fyi/pkgf/test", extra="--json @${pkgfPayload}")
    testremote.succeed("[[ -f /var/log/caddy/access-:80.log ]]")

    hydrangea.wait_for_unit("emojos-dot-in")
    fetch("https://emojos.in")

    hydrangea.wait_for_unit("writefreely")
    fetch("https://daily.iliana.fyi/login")

    skyrabbit.wait_for_unit("caddy")
    skyrabbit.wait_for_unit("phpfpm-mediawiki")
    fetch("https://skyrabbit.7x6.net/index.php?title=Main_Page", f=skyrabbit.wait_until_succeeds)
    fetch("https://skyrabbit.7x6.net/resources/assets/poweredby_mediawiki_88x31.png", f=skyrabbit.wait_until_succeeds)
    fetch("https://skyrabbit.7x6.net/", f=skyrabbit.wait_until_succeeds)
  '';
}
