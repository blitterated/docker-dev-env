FROM ubuntu

MAINTAINER blitterated blitterated@protonmail.com

WORKDIR /root
COPY bash_profile .bash_profile
COPY bashrc .bashrc
COPY provision/*.* provision/

COPY utils/container/bounce /usr/bin/bounce
COPY utils/container/path /usr/bin/path
COPY utils/container/docker-s6-quick-exit /usr/bin/docker-s6-quick-exit

RUN ./provision/apt_prep.sh
RUN ./provision/manpages.sh
RUN ./provision/apt_install.sh
RUN ./provision/s6-overlay.sh

ENTRYPOINT ["/init"]
