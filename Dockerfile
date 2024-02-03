# syntax=docker/dockerfile:1

FROM ubuntu

MAINTAINER blitterated blitterated@protonmail.com

WORKDIR /root
COPY shell/bash_profile .bash_profile
COPY shell/bashrc .bashrc
COPY shell/source_files.sh .source_files.sh
COPY dde.rc/*.* .dde.rc/
COPY provision/manpages.sh .provision/

RUN <<EOT bash -xev
  apt update && apt --yes upgrade

  # bring back the manpages
  ./.provision/manpages.sh

  # compression / archiving
  apt --yes install gzip
  apt --yes install tar
  apt --yes install xz-utils
  apt --yes install unzip

  # utils
  apt --yes install tmux
  apt --yes install psmisc # a collection of process utils including pstree
  apt --yes install tree
  apt --yes install htop
  apt --yes install silversearcher-ag
  apt --yes install curl

  # editing
  apt --yes install ed
  apt --yes install vim
  apt --yes install bash-completion

  # dev
  apt --yes install build-essential
  apt --yes install git

  # for some reason, man pages for these don't install on first pass.
  # or they don't get installed for certain preinstalled packages.
  apt --reinstall --yes install gzip tar bash
EOT

ENTRYPOINT ["/bin/bash"]
