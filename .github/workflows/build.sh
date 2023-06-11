# shellcheck shell=bash

set -euxo pipefail

mkdir ~/.ssh
cp .github/workflows/known_hosts ~/.ssh/known_hosts

git config user.name "$GITHUB_ACTOR"
git config user.email "$GITHUB_ACTOR@users.noreply.github.com"
git fetch origin refs/notes/nix-store:refs/notes/nix-store

finish() {
    ./x.py fetch-notes
    git push origin refs/notes/nix-store
}
trap finish EXIT

./x.py ci
