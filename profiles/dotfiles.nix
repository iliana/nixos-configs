{ config, lib, dotfiles, ... }: {
  system.activationScripts.ilianaDotfiles = lib.stringAfter [ "users" ] ''
    ln -sfn "${dotfiles}" ~iliana/.dotfiles
    cp -rsf ~iliana/.dotfiles/. ~iliana
    # find broken links to ~/.dotfiles and delete them
    find ~iliana -lname ~iliana/.dotfiles/'*' -xtype l -delete
  '';
}
