_: let
  handlers = {
    "/" = "redir https://iliana.fyi";
    "/feed.xml" = "redir https://iliana.fyi/atom.xml";
    "/8631E022.txt" = "redir https://iliana.fyi/8631E022.txt";
    "/assets/con404.pdf" = "redir https://files.iliana.fyi/con404.pdf";
    "/lowercase/" = "redir https://iliana.fyi/lowercase/";

    "/blog/2020/07/etaoin/" = "redir https://iliana.fyi/blog/etaoin/";
    "/blog/2020/01/installing-fedora-on-mac-mini/" = "redir https://iliana.fyi/blog/installing-fedora-on-mac-mini/";
    "/blog/2019/08/fitting-rooms-for-your-name/" = "redir https://iliana.fyi/blog/fitting-rooms-for-your-name/";
    "/blog/2018/12/everything-that-lives-is-designed-to-end/" = "redir https://iliana.fyi/blog/everything-that-lives-is-designed-to-end/";
    "/blog/2018/12/e98e/" = "redir https://iliana.fyi/blog/e98e/";

    "/blog/2020/06/so-you-want-to-recall-the-mayor/" = "redir https://web.archive.org/web/20200815201535/https://linuxwit.ch/blog/2020/06/so-you-want-to-recall-the-mayor/";
    "/blog/2020/02/the-future-of-rusoto/" = "redir https://web.archive.org/web/20210209150819/https://linuxwit.ch/blog/2020/02/the-future-of-rusoto/";
    "/blog/2019/05/webscale-website-webstats/" = "redir https://web.archive.org/web/20210412040719/https://linuxwit.ch/blog/2019/05/webscale-website-webstats/";
    "/blog/2019/03/pride-flag-buying-guide-for-politicians/" = "redir https://web.archive.org/web/20210412023550/https://linuxwit.ch/blog/2019/03/pride-flag-buying-guide-for-politicians/";
    "/blog/2019/01/use-pronouns-as-listed/" = "redir https://web.archive.org/web/20210412032400/https://linuxwit.ch/blog/2019/01/use-pronouns-as-listed/";
  };
in {
  iliana.caddy.virtualHosts = {
    "linuxwit.ch" = handlers;
    "www.linuxwit.ch" = handlers;
  };
}
