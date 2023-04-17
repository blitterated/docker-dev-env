set -e

apt --yes install gzip tar xz-utils unzip \
          curl bash-completion ed vim tmux \
          psmisc tree htop \
          git silversearcher-ag

# NOTE: psmisc is a collection of process utils inc. pstree.

# for some reason, man pages for these don't install on first pass.
# or they don't get installed for certain preinstalled packages.
apt --reinstall --yes install gzip tar bash
