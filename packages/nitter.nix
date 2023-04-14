{ nitter, gitMinimal, fetchFromGitHub, ... }: nitter.overrideAttrs (old: {
  version = "unstable-2023-03-28";
  src = fetchFromGitHub {
    leaveDotGit = true;
    owner = "zedeus";
    repo = "nitter";
    rev = "95893eedaa2fb0ca0a0a15257d81b720f7f3eb67";
    hash = "sha256-3lQgKPnEagpJi1YT69ANZUpwhjY3HhdhKpkbsQo2Xn0=";
  };
  nativeBuildInputs = old.nativeBuildInputs ++ [ gitMinimal ];
  patches = [ ];
})
