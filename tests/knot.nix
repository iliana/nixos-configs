{
  megaera,
  pkgs,
  ...
}: let
  zones = pkgs.writeTextDir "example.com.zone" ''
    @ IN SOA ns.example.net. noc.example.com. 1312 7200 3600 1209600 3600
    @ IN NS ns.example.net.
    @ IN A 198.51.100.69
  '';
  zoneTar = pkgs.runCommand "zones.tar" {} ''
    cd ${zones}
    tar cf $out ./*.zone
  '';
in {
  nodes = {
    inherit megaera;
    client = {
      config,
      lib,
      pkgs,
      ...
    }: {
      environment.systemPackages = [pkgs.dig];
    };
  };

  testScript = ''
    start_all()
    megaera.wait_for_unit("knot")

    stdout = client.succeed("dig +short chaos txt id.server @megaera")
    assert stdout.strip() == '"megaera"'

    client.fail("nslookup example.com megaera")
    megaera.succeed("sudo -u dns-admin /etc/profiles/per-user/dns-admin/bin/import-zones <${zoneTar}")
    stdout = client.succeed("nslookup example.com megaera")
    assert "198.51.100.69" in stdout
  '';
}
