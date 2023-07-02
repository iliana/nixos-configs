{
  hydrangea,
  skyrabbit,
  pkgs,
  runTest,
  ...
}:
runTest {
  nodes = {
    inherit hydrangea skyrabbit;
    testremote = {pkgs, ...}: {
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
    from urllib.parse import urlparse

    def fetch(url, f=hydrangea.wait_until_succeeds, extra=""):
        parsed = urlparse(url)
        port = 80 if parsed.scheme == "http" else 443
        cmd = f"curl -fks --resolve {parsed.hostname}:{port}:127.0.0.1 {url} {extra}"
        f(cmd.strip(), timeout=15)

    start_all()

    hydrangea.wait_for_unit("caddy")
    fetch("https://hydrangea.ili.fyi/yo")
    fetch("https://haha.business")

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
  '';
}
