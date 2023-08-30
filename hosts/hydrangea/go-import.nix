{lib, ...}: let
  # There is currently nothing worth importing from these URLs but I have
  # nerdsniped myself into setting this up and seeing if it works.
  imports = {
    "iliana.fyi/striped" = {repo = "https://github.com/iliana/striped";};
  };

  cfg = path: {
    repo,
    branch ? "main",
  }: let
    go-source =
      if (lib.hasPrefix "https://github.com/" repo)
      then {
        home = repo;
        directory = "${repo}/tree/${branch}\\{/dir\\}";
        file = "${repo}/blob/${branch}\\{/dir\\}/\\{file\\}#L\\{line\\}";
      }
      else null;
  in ''
    route {
      @go-get query go-get=1
      header @go-get content-type "text/html; charset=utf-8"
      respond @go-get <<HTML
        <meta name="go-import" content="${path} git ${repo}">
        ${lib.optionalString (go-source != null) ''<meta name="go-source" content="${path} ${go-source.home} ${go-source.directory} ${go-source.file}">''}
      HTML
      redir ${repo}
    }
  '';

  hosts = builtins.map (path: builtins.head (lib.splitString "/" path)) (builtins.attrNames imports);
  byHost = host:
    lib.mapAttrs'
    (path: repo: lib.nameValuePair (lib.removePrefix host path) (cfg path repo))
    (lib.filterAttrs (name: _: lib.hasPrefix host name) imports);
in {
  iliana.caddy.virtualHosts = lib.genAttrs hosts byHost;
}
