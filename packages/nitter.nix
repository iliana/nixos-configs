{ nitter, fetchFromGitHub, ... }: nitter.overrideAttrs (old: {
  version = "unstable-2023-03-28";
  src = fetchFromGitHub {
    owner = "zedeus";
    repo = "nitter";
    rev = "23f4c6114c2b790405a9cefef1a7979655de44d4";
    hash = "sha256-Tv10M/t1b6KwS702duVZK58sVfLup4aOemT/I2k8rp4=";
  };
})
