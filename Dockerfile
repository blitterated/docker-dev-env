FROM alpine

MAINTAINER blitterated blitterated@protonmail.com

COPY bash_profile /root/.bash_profile
COPY bashrc /root/.bashrc

RUN apk --update add \
        bash bash-doc bash-completion \
        curl curl-doc git git-doc \
        less less-doc
