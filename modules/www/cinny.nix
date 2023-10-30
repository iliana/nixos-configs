{
  helpers,
  lib,
  pkgs,
  ...
}: {
  iliana.www.virtualHosts = lib.genAttrs ["cinny.7x6.net"] (_: {
    "*" = helpers.caddy.serve pkgs.cinny;
    "/login" = "redir * /";
    "/register" = "redir * /";
  });
}
