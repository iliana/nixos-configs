{...}: {
  security.acme = {
    defaults = {
      email = "iliana@buttslol.net";
      server = "https://acme-v02.api.letsencrypt.org/directory";
    };
  };
}
