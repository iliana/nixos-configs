{
  hydrangea,
  runTest,
  ...
}:
runTest {
  nodes = {inherit hydrangea;};
  testScript = ''
    from urllib.parse import urlparse

    def fetch(url):
        parsed = urlparse(url)
        port = 80 if parsed.scheme == "http" else 443
        cmd = f"curl -fks --resolve {parsed.hostname}:{port}:127.0.0.1 {url}"
        hydrangea.wait_until_succeeds(cmd, timeout=15)

    hydrangea.wait_for_unit("caddy")
    fetch("https://haha.business")

    hydrangea.wait_for_unit("container@emojos")
    fetch("https://emojos.in")

    hydrangea.wait_for_unit("container@nitter")
    fetch("http://nitter.home.arpa/about")
  '';
}
