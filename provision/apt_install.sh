apt --yes install tree gzip tar xz-utils \
          curl bash-completion ed vim tmux \
          git silversearcher-ag

# for some reason, man pages for these don't install on first pass.
# or they don't get installed for certain preinstalled packages.
apt --reinstall --yes install gzip tar bash
