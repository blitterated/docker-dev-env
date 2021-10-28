FROM alpine

MAINTAINER blitterated blitterated@protonmail.com

COPY bash_profile /root/.bash_profile
COPY bashrc /root/.bashrc

RUN apk --update add \
        mandoc man-pages mandoc-apropos \
        less less-doc \
        bash bash-doc bash-completion \
        curl curl-doc \
        git git-doc \
        the_silver_searcher \
        neovim
