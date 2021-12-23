FROM ubuntu

MAINTAINER blitterated blitterated@protonmail.com

COPY bash_profile /root/.bash_profile
COPY bashrc /root/.bashrc
COPY provision.sh /root/provision.sh

RUN /root/provision.sh
