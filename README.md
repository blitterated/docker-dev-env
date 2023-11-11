# Docker Dev Environment

## Intent

This concept is not for creating containers ready for production deployment. Instead the intent is to code without polluting the host development machine, and to deploy the project to a production runtime that is most likely not container based, e.g. a static website whose tooling has live/hot reload built in. It's simply another way to achieve a deeper kind of segregation along the lines of `virtualenv` or `bundle install --local`.

## Contents

It adds the following onto the Ubuntu base image:

   * Brings back the man pages
   * `gzip`
   * `tar`
   * `xz-utils`
   * `unzipcurl`
   * `bash-completion`
   * `ed`
   * `vim`
   * `tmux`
   * `psmisc`
   * `tree`
   * `htop`
   * `git`
   * the silversearcher (`ag`)

__NOTE:__ `psmisc` is a collection of process utils inc. `pstree`.

## Config files

This is meant to be a base image for building more focused build time and dev time images. I really don't like using `echo` or `sed` to add lines to `.bashrc`, so I've opted to have `.bashrc` source all files found in the `~/.dde.rc` directory in the image. Just drop any extra shell configuration in a file in that directory, and it will get sourced.

## Building and Running

### Build the docker-dev-env image from Dockerfile

```sh
docker build -t dde .
```

### Run the docker-dev-env image

```sh
docker run -it --rm dde /bin/bash
```

##  There's more info in the [wiki](https://github.com/blitterated/docker_dev_env/wiki)
