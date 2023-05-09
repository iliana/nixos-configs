# shellcheck shell=bash
ln -sfn "$1" "$2"/.dotfiles
cp -rsf --no-preserve=mode,ownership "$2"/.dotfiles/. "$2"
# find broken links to $2/.dotfiles and delete them
find "$2" -lname "$2"/.dotfiles/'*' -xtype l -delete -print
