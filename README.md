# Docker Dev Environment

## Intent

This concept is not for creating containers ready for production deployment. Instead the intent is to code without polluting the development machine, and to deploy the project to a production runtime that is most likely not container based. It's simply another way to achieve a deeper kind of segregation along the lines of `virtualenv` or `bundle install --local`.

## Goals
* Segregate project dependencies and runtimes from the host OS
* Run project code and tests in the container
* Keep code on host OS, use bind mounts not volumes
* Edit code with tools on host OS

### Questions
* If nothing needs to be running in the container, then what's going to be running when the container is started?
    * There is a simple zombie eating PID1 process you get when you start Docker with `--init`. It can only handle a single child process. It was `tini`, but maybe that's changed?
    * There are other init processes available like s6, tini, runit, supervisord, monit, and others
* Do we need a container if just a union mount filesystem will do?
    * Yes you need a container. The filesystems are unioned in the kernel.
* Most container + init strategies have the whole container fail if one of the services' processes fails. This is so Kubernetes and the like can clean up and restart a container. Is that what I want here?
    * Probably not. It might come in handy to explore a half dead container that was running the project code during development. OTOH, maybe all this should just be logged to a bind mount. 

### Stretch Goals
* Have an init process running
   * spin up services that may be needed such as cron, sshd, and syslog
   * catch zombie processes
* ssh key forwarding from host with ssh-agent
   * Is this needed? The main usecase is git cloning, but if the files are stored on the host's filesystem then we don't need git or ssh access in the container.
* logging issues with syslog
   * Is this needed? The only usecase is if the code in question will be run in the container for testing. More than likely, this will be true. We will run the code in the container. The language runtime (`ruby`, `python`, et. al.) *is* one of the dependencies I'm trying to segregate.

## Building and Running

### Build the docker-dev-env image from Dockerfile

```sh
docker build -t dde .
```

### Run the docker-dev-env image

```sh
docker run -it --rm --init dde /bin/bash
```

##  There's more info in the [wiki](https://github.com/blitterated/docker_dev_env/wiki)