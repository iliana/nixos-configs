# shellcheck shell=bash
ln -sfn "$1" ~/.dotfiles
cp -rsf --no-preserve=mode,ownership ~/.dotfiles/. ~
# find broken links to ~/.dotfiles and delete them
find ~ -lname ~/.dotfiles/'*' -xtype l -delete -print
