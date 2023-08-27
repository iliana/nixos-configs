# Tailscale policy rules that don't fit in any other modules.
{
  acls = [
    {
      action = "accept";
      src = ["iliana@github"];
      proto = ["tcp" "udp"];
      dst = [
        "iliana@github:*"
        "autogroup:internet:*"
        "100.111.252.113:*"
      ];
    }
    {
      action = "accept";
      src = ["iliana@github"];
      proto = "tcp";
      dst = [
        "tag:home-assistant:80"
        "tag:server:22"
      ];
    }
    {
      action = "accept";
      src = ["autogroup:shared"];
      proto = "tcp";
      dst = ["100.113.241.94:22"];
    }
  ];

  ssh = [
    {
      action = "accept";
      src = ["iliana@github"];
      dst = ["iliana@github" "tag:server"];
      users = ["iliana"];
    }
  ];

  tags = [
    "tag:home-assistant"
    "tag:server"
    "tag:tartarus"
  ];

  tests = [
    {
      user = "iliana@github";
      allow = ["iliana@github:1312" "alecto:53" "1.1.1.1:443" "172.20.3.69:22"];
    }
    {
      user = "tag:server";
      allow = ["alecto:53"];
      deny = ["iliana@github:22" "tag:server:22" "1.1.1.1:443" "172.20.3.69:22"];
    }
  ];
}
