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
## Utility Scripts

### Container

These are available in `/usr/bin` in the container. `/usr/bin` is in the container's `PATH` by default, so you can use these from the container's shell. These will also be available to any upstream images.

#### bounce

This execline script bounces any services you've installed with the `s6-rc` method.

#### path

This execline script prints out the system paths found in the `$PATH` environment variable on separate lines.

#### docker-s6-quick-exit / qb

This execline script will shut down the s6 supervisor tree from the top down IMMEDIATELY, and then `exit`.

You must `exec` this script for it to work properly. There is a Bash function called `qb` (quick bail) in `.bashrc` that does this.

Only use this if you don't care about jacking up a container. Typical usage is when iterating quickly on partially completed images to reduce the shutdown from the default 6 seconds to near 0.



##  There's more info in the [wiki](https://github.com/blitterated/docker_dev_env/wiki)
