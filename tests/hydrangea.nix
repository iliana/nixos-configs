{
  hydrangea,
  pkgs,
  runTest,
  ...
}:
runTest {
  nodes = {inherit hydrangea;};
  testScript = let
    pkgfPayload = pkgs.writeText "pkgf-payload.json" (builtins.toJSON {
      text = "You received ... pickup now.";
    });
    httpRes = pkgs.writeText "http-response" ''
      HTTP/1.1 200 OK
      content-type: text/plain
      content-length: 4

      thx
    '';
  in ''
    from urllib.parse import urlparse

    def fetch(url, f=hydrangea.wait_until_succeeds, extra=""):
        parsed = urlparse(url)
        port = 80 if parsed.scheme == "http" else 443
        cmd = f"curl -fks --resolve {parsed.hostname}:{port}:127.0.0.1 {url} {extra}"
        f(cmd.strip(), timeout=15)

    hydrangea.wait_for_unit("caddy")
    fetch("https://haha.business")

    hydrangea.succeed("nc -l 42069 <${httpRes} >/http.req &")
    fetch("https://hydrangea.ili.fyi/pkgf", extra="-X POST --data @${pkgfPayload}")
    hydrangea.succeed("grep -q 'content.*received.*pickup' /http.req")
    fetch("https://hydrangea.ili.fyi/pkgf", f=hydrangea.fail)

    hydrangea.wait_for_unit("container@emojos")
    fetch("https://emojos.in")

    hydrangea.wait_for_unit("container@nitter")
    fetch("http://nitter.home.arpa/about")
  '';
}
