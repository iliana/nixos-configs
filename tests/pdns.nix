{ megaera, ... }: {
  nodes = { inherit megaera; };
  testScript = ''
    megaera.start()
    megaera.wait_for_unit("pdns")
  '';
}
