apt --yes install tree gzip tar curl \
          bash-completion \
          git silversearcher-ag vim

# for some reason, man pages for these don't install on first pass
apt --reinstall --yes install gzip tar
