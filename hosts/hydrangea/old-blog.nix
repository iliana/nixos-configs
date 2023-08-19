{config, ...}: {
  iliana.caddy.virtualHosts = with config.iliana.caddy.helpers; {
    "linuxwit.ch" = redirMap {
      "/" = "https://iliana.fyi";
      "/feed.xml" = "https://iliana.fyi/atom.xml";
      "/8631E022.txt" = "https://iliana.fyi/8631E022.txt";
      "/assets/con404.pdf" = "https://files.iliana.fyi/con404.pdf";
      "/lowercase/" = "https://iliana.fyi/lowercase/";

      "/blog/2020/07/etaoin/" = "https://iliana.fyi/blog/etaoin/";
      "/blog/2020/01/installing-fedora-on-mac-mini/" = "https://iliana.fyi/blog/installing-fedora-on-mac-mini/";
      "/blog/2019/08/fitting-rooms-for-your-name/" = "https://iliana.fyi/blog/fitting-rooms-for-your-name/";
      "/blog/2018/12/everything-that-lives-is-designed-to-end/" = "https://iliana.fyi/blog/everything-that-lives-is-designed-to-end/";
      "/blog/2018/12/e98e/" = "https://iliana.fyi/blog/e98e/";

      "/blog/2020/06/so-you-want-to-recall-the-mayor/" = "https://web.archive.org/web/20200815201535/https://linuxwit.ch/blog/2020/06/so-you-want-to-recall-the-mayor/";
      "/blog/2020/02/the-future-of-rusoto/" = "https://web.archive.org/web/20210209150819/https://linuxwit.ch/blog/2020/02/the-future-of-rusoto/";
      "/blog/2019/05/webscale-website-webstats/" = "https://web.archive.org/web/20210412040719/https://linuxwit.ch/blog/2019/05/webscale-website-webstats/";
      "/blog/2019/03/pride-flag-buying-guide-for-politicians/" = "https://web.archive.org/web/20210412023550/https://linuxwit.ch/blog/2019/03/pride-flag-buying-guide-for-politicians/";
      "/blog/2019/01/use-pronouns-as-listed/" = "https://web.archive.org/web/20210412032400/https://linuxwit.ch/blog/2019/01/use-pronouns-as-listed/";
    };
    "www.linuxwit.ch" = redirPrefix "https://linuxwit.ch";
  };
}
