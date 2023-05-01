{ pkgs, megaera, ... }:
let
  zones = pkgs.writeTextDir "example.com.zone" ''
    @ IN SOA ns.example.com. noc.example.com. 1234567890 7200 3600 1209600 3600
    @ IN NS ns.example.com.
    @ IN A 198.51.100.69
  '';
  zoneTar = pkgs.runCommand "zones.tar" { } ''
    cd ${zones}
    tar cf $out ./*.zone
  '';
in
{
  nodes = {
    inherit megaera;
    client = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.dig ];
    };
  };

  testScript = ''
    start_all()
    megaera.wait_for_unit("pdns")

    stdout = client.succeed("dig +short chaos txt id.server @megaera")
    assert stdout.strip() == '"megaera"'

    client.fail("nslookup example.com megaera")
    megaera.succeed("sudo -u pdns-deploy /etc/profiles/per-user/pdns-deploy/bin/pdns-load <${zoneTar}")
    stdout = client.succeed("nslookup example.com megaera")
    assert "198.51.100.69" in stdout
  '';
}
