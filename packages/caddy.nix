{caddy}:
caddy.overrideAttrs (old: {
  patches =
    (old.patches or [])
    ++ [
      # https://github.com/caddyserver/caddy/pull/5463 backported to v2.6.4
      # 1aef807c71b1ea8e70e664765e0010734aee468c..52459de4583c15f2caf5d5d21b0fb03ed16f7850
      ./caddy-5463.patch
    ];

  ldflags = old.ldflags ++ ["-X github.com/caddyserver/caddy/v2.CustomVersion=${old.version}+iliana"];
})
