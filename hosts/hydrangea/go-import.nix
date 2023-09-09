{lib, ...}: let
  goGet = repo: let
    path = "{host}{path}";
    branch = "main";
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
in {
  iliana.caddy.virtualHosts = {
    "iliana.fyi"."/striped" = goGet "https://github.com/iliana/striped";
  };
}
