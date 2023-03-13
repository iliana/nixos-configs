# shellcheck shell=bash
ln -sfn "$1" ~/.dotfiles
cp -rsf ~/.dotfiles/. ~
# find broken links to ~/.dotfiles and delete them
find ~ -lname ~/.dotfiles/'*' -xtype l -delete
