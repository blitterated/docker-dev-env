FROM ubuntu

MAINTAINER blitterated blitterated@protonmail.com

WORKDIR /root
COPY bash_profile .bash_profile
COPY bashrc .bashrc
COPY provision.sh provision.sh
COPY provision/*.* provision/

RUN ./provision/apt_prep.sh
RUN ./provision/manpages.sh
RUN ./provision/apt_install.sh
RUN ./provision/s6-overlay.sh

ENTRYPOINT ["/init"]
