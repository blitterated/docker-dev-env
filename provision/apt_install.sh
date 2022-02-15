apt --yes install gzip tar xz-utils unzip \
          curl bash-completion ed vim tmux \
          tree git silversearcher-ag

# for some reason, man pages for these don't install on first pass.
# or they don't get installed for certain preinstalled packages.
apt --reinstall --yes install gzip tar bash
