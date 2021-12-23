# Docker Dev Environment

I'm not so worried about a single process running isolated in Docker as I am having an isolated filesystem that is unpolluted with dependencies and runtimes from other projects. In return, neither can this isolated filesystem pollute the filesystem of the host OS.

## Intent
* This concept is not for creating containers ready for production deployment. Instead the intent is to code without polluting the developers' machines, and to deploy the project to a production runtime that is not container based. It's simply another way to achieve a deeper kind of segregation along the lines of virtualenv or asdf.

## Goals
* Segregate project dependencies and runtimes from the host OS
* Run project code and tests in the container
* Keep code on host OS, use bind mounts not volumes
* Edit code with tools on host OS

### Questions
* If nothing needs to be running in the container, then what's going to be running when the container is started?
    * There is a simple zombie eating process you get when you start Docker with `--init`
    * There are other init processes available like s6, tini, runit, supervisord, monit, and others
* Do we need a container if just a union mount filesystem will do?
    * Yes you need a container. The filesystems are unioned in the kernel.

### Stretch Goals
* Have an init process running
   * spin up services that may be needed such as ssh and syslog
   * catch zombie processes
* ssh key forwarding from host with ssh-agent
   * Is this needed? The main usecase is git cloning, but if the files are stored on the host's filesystem then we don't need git or ssh access in the container.
* logging issues with syslog
   * Is this needed? The only usecase is if the code in question will be run in the container for testing. More than likely, this will be true. We will run the code in the container. The language runtime (`ruby`, `python`, et. al.) *is* one of the dependencies.



## Setup the repo

```sh
git init
```

### Setup the git user and email

```sh
git config user.name "blitterated"
git config user.email "blitterated@protonmail.com"
```

#### double check

```sh
git config -l
git config --local -l
git config user.name
git config user.email
```

## Play around with default images for different distros

- Arch

  ```sh
  docker run -it --rm --init archlinux bash
  ```
  ```sh
  # update packages
  pacman -Syy

  # see if Vim is already installed
  pacman -Qi vim

  # search for the Vim package
  apt-cache search vim

  # install Vim
  pacman -S vim
  ```

- Alpine

  ```sh
  docker run -it --rm --init alpine /bin/ash
  ```
  ```sh
  # update packages
  apk update

  # see if Vim is already installed
  apk -e info vim

  # search for the Vim package
  apk search vim

  # install Vim
  apk add vim
  ```

- Ubuntu (Minimal)

  ```sh
  docker run -it --rm --init ubuntu bash
  ```
  ```sh
  # update packages
  apt update

  # see if Vim is already installed
  dpkg -S toto
  dpkg -l toto

  # search for the Vim package
  apt-cache search vim

  # install Vim
  apt install vim
  ```


- Minimal Debian, by Bitnami

  ```sh
  docker run -it --rm --init bitnami/minideb:latest bash
  ```
  ```sh
  # update packages
  apt update

  # see if Vim is already installed
  dpkg -S toto
  dpkg -l toto

  # search for the Vim package
  apt-cache search vim

  # install Vim
  apt install vim
  ```

## Generate an ssh key for github

```sh
ssh-keygen -t ed25519 -C "git@blitterated.com"
```

## Create an Alpine Docker image

### Create a bash_profile for Docker image

```sh
cat << EOF > bash_profile
# load .bashrc by default
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
EOF
```

### Create a bashrc for Docker image

```sh
cat << EOF > bashrc
export PAGER=less
EOF
```

### Create a Dockerfile

```sh
cat <<"EOF" > Dockerfile
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
        openssh-client \
        the_silver_searcher \
        neovim
EOF
```

### Build the docker-dev-env image from Dockerfile

```sh
docker build -t dde .
```

### Run the docker-dev-env image

```sh
docker run --rm -it dde /bin/bash
```

## Setup man pages in a conatiner

This is based on experimentation to find out how to get manpages setup on a minimized Debian, Ubuntu, or Phusion container. I'm don't want to run `unminimize` and reinstall everything that was removed, just some manpages. This will all wind up in the `Dockerfile`.

Always update the package list first. Otherwise you man not be able to find any packages while searching

```sh
apt update
```

`man-db` needs something for displaying pages. Dialog is preferred, but it will fall back to Readline during installation.

```sh
apt install dialog
```

Next, install man-db.

```sh
apt install man-db
```

### confusing issues ensued

Running `man man` at this point will give you a message letting you now that the system has been minimized, and you should run unminimize. 

```
This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, including manpages, you can run the 'unminimize'
command. You will still need to ensure the 'man-db' package is installed.
```

So the `man` executable has not been replaced. Initially, I thought it was because there was _already_ an executable in place. I tried deleting it first before installing on a new container:

```sh
apt update
rm $(which man)
apt install dialog
apt install man-db
```

But now installation of man-db was failing because it couldn't find the `man` executable. Why would `apt` need the `man` executable to be in place already when installing `man`? I decided to take a look at the `unminimize` script itself and found this code near the end:

```sh
if  [ "$(dpkg-divert --truename /usr/bin/man)" = "/usr/bin/man.REAL" ]; then
    # Remove diverted man binary
    rm -f /usr/bin/man
    dpkg-divert --quiet --remove --rename /usr/bin/man
fi
```

Ah! `apt` usually uses `dpkg` behind the scenes. This offers a hint as to why `apt install man-db` needed `man` to be in place already. So [what is dpkg-divert doing](https://linux.die.net/man/8/dpkg-divert)?


> dpkg-divert is the utility used to set up and update the list of diversions.

>File diversions are a way of forcing dpkg(1) not to install a file into its location, but to a diverted location. Diversions can be used through the Debian package scripts to move a file away when it causes a conflict. System administrators can also use it to override some package's configuration file, or whenever some files (which aren't marked as 'conffiles') need to be preserved by dpkg, when installing a newer version of a package which contains those files.

Let's see a list of what's being diverted then:

```sh
dpkg-divert --list
```

```
local diversion of /sbin/initctl to /sbin/initctl.distrib
diversion of /usr/share/man/man1/sh.1.gz to /usr/share/man/man1/sh.distrib.1.gz by dash
local diversion of /usr/bin/man to /usr/bin/man.REAL
diversion of /bin/sh to /bin/sh.distrib by dash
```

Now we're getting somewhere. Let's try installing `man-db` again in a fresh container.

```sh
apt update
apt install dialog
apt install man-db
```

Next, try running `man.REAL`

```sh
man.REAL man
```

```
No manual entry for man
```

Yes! that's a working `man` install, albeit with no entries. Finally, let's try running the cleanup lines from the `unminimize` script, and then `man man`.

```sh
rm -f /usr/bin/man
dpkg-divert --quiet --remove --rename /usr/bin/man
man man
```

```
No manual entry for man
```

Success! All that's left now is to install some manpages.

Ultimately, I still don't know why `apt` install fails when deleting a file that's been diverted, in this case `/usr/bin/man`. I think that's a deeper exploration than necessary right now. I understand enough to cleanly unwind what's been minimized, and I'm happy to have man pages again.

## Connect to Docker's secret Linux VM

### connect using nsenter1

It's had many names over the years on Mac: boot2docker, Moby, LinuxKit...

```
docker run -it --rm --privileged --pid=host justincormack/nsenter1
```

### connect to serial tty on mac using c-kermit

```sh
# old, pre 2018
kermit -l ~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/tty -b 38400

# old as of 2021
kermit -l ~/Library/Containers/com.docker.docker/Data/vms/0/tty -b 38400
```

| cmd/switch | purpose |
| --- | --- |
| -l    | SET LINE or SET PORT |
| -b    | SET SPEED |
| C     | CONNECT |
| ctrl-\ ctrl-c | disconnect |


## Create a Docker volume

Or, why using Docker volumes is a bad idea for development. The volumes are stored inside the Linux kernel instance that is the  host for all the guest docker kernels, and not via a bound volume to the root OS' filesystem. Of course if your root OS is Linux, then you're fine


### Create a new volume

```sh
docker volume create my-vol
```

### Mount the volume to a container

```sh
docker run -it --rm --init -v my-vol:/foo dde /bin/ash
```

### Clone a git repo into the volume

```sh
```

### Shut down the container and view the volume with nsenter1

```sh
```

### Peek at where the volume is stored on the Docker Linux VM image

```sh
docker run -it --rm --privileged --pid=host justincormack/nsenter1

# ls /var/lib/docker/volumes/
```

### List out the contents of the volume with a busybox container

```sh
```

### Bind mount the volume to Mac OS using a busybox container

```sh
```



# Issues

## Error while using `apk search` with Alpine. 

This was before switching to Arch and then Debian based images

```
bash-5.1# apk search ag
WARNING: Ignoring https://dl-cdn.alpinelinux.org/alpine/v3.14/main: No such file or directory
WARNING: Ignoring https://dl-cdn.alpinelinux.org/alpine/v3.14/community: No such file or directory
```

`curl`ing with headers shows that we're being redirected to the same URL, but with a trailing slash. See the `location` field in the header

```
λ ~: curl -i https://dl-cdn.alpinelinux.org/alpine/v3.14/main
HTTP/2 301
server: nginx
content-type: text/html
location: http://dl-cdn.alpinelinux.org/alpine/v3.14/main/
strict-transport-security: max-age=31536000
x-frame-options: DENY
x-content-type-options: nosniff
via: 1.1 varnish, 1.1 varnish
accept-ranges: bytes
date: Wed, 07 Jul 2021 03:00:03 GMT
age: 0
x-served-by: cache-lga21974-LGA, cache-dal21283-DAL
x-cache: MISS, MISS
x-cache-hits: 0, 0
x-timer: S1625626804.787410,VS0,VE113
content-length: 162

<html>
<head><title>301 Moved Permanently</title></head>
<body>
<center><h1>301 Moved Permanently</h1></center>
<hr><center>nginx</center>
</body>
</html>
```

If we `curl` the same URL with the trailing slash, everything seems fine.

```
λ ~: curl -i https://dl-cdn.alpinelinux.org/alpine/v3.14/main/
HTTP/2 200
server: nginx
content-type: text/html
strict-transport-security: max-age=31536000
x-frame-options: DENY
x-content-type-options: nosniff
via: 1.1 varnish, 1.1 varnish
accept-ranges: bytes
date: Wed, 07 Jul 2021 02:59:52 GMT
age: 0
x-served-by: cache-lga21929-LGA, cache-dal21242-DAL
x-cache: MISS, MISS
x-cache-hits: 0, 0
x-timer: S1625626792.238700,VS0,VE114

<html>
<head><title>Index of /alpine/v3.14/main/</title></head>
<body>
<h1>Index of /alpine/v3.14/main/</h1><hr><pre><a href="../">../</a>
<a href="aarch64/">aarch64/</a>                                           30-Jun-2021 15:35                   -
<a href="armhf/">armhf/</a>                                             30-Jun-2021 15:35                   -
<a href="armv7/">armv7/</a>                                             30-Jun-2021 15:35                   -
<a href="mips64/">mips64/</a>                                            30-Jun-2021 15:35                   -
<a href="ppc64le/">ppc64le/</a>                                           05-Jul-2021 18:31                   -
<a href="s390x/">s390x/</a>                                             30-Jun-2021 15:35                   -
<a href="x86/">x86/</a>                                               30-Jun-2021 15:35                   -
<a href="x86_64/">x86_64/</a>                                            30-Jun-2021 15:35                   -
</pre><hr></body>
</html>
```

If I open `/etc/apk/repositories` and add the trailing slashes, then run `apk search ag`, there's a new error:

```
WARNING: Ignoring https://dl-cdn.alpinelinux.org/alpine/v3.14/main/: No such file or directory
```

Ultimately, it turns out that deleting apt lists and apk cache in the `RUN` command of your Dockerfile is a bad idea for an image you're iterating on. So don't do this:

```
RUN apk --update add \
      ... && \
    rm -rf /var/lib/apt/lists/* && \
    rm /var/cache/apk/*
```




# Resources
* Docker
  * [Use containers for development](https://docs.docker.com/language/nodejs/develop/)
  * [Do not ignore .dockerignore](https://codefresh.io/docker-tutorial/not-ignore-dockerignore-2/)
  * [YT: Docker Developer Environments](https://www.youtube.com/watch?v=9TM4Ry986oY)
  * [YT: Docker Build: Exploring Docker Dev Environments](https://www.youtube.com/watch?v=JsgLV6C9VQQ)
  * [Development Environments Preview](https://docs.docker.com/desktop/dev-environments/)
  * [Tech Preview: Docker Dev Environments](https://www.docker.com/blog/tech-preview-docker-dev-environments/)
  * [Reusable development containers with Docker Compose and Dip](https://evilmartians.com/chronicles/reusable-development-containers-with-docker-compose-and-dip)
  * [Where are Docker Images Stored? Docker Container Paths Explained](https://www.freecodecamp.org/news/where-are-docker-images-stored-docker-container-paths-explained/)
  * [GH: nsenter1 Docker image](https://github.com/justincormack/nsenter1)
* Docker Volumes
  * [Use volumes](https://docs.docker.com/storage/volumes/)
  * [Manage data in Docker](https://docs.docker.com/storage/)
  * [Mount a docker volume on an OS X host](https://stackoverflow.com/a/62293840)
* Alpine Linux
  * [apk search](https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management#Search_for_Packages)
  * [SO: How to install Go in alpine linux](https://stackoverflow.com/questions/52056387/how-to-install-go-in-alpine-linux)
* VSCode
   * [Developing inside a Container](https://code.visualstudio.com/docs/remote/containers)
* Linux Kit
  * [GH linuxkit](https://github.com/linuxkit/linuxkit)
  * [Announcing LinuxKit](https://www.docker.com/blog/introducing-linuxkit-container-os-toolkit/)
  * [busybox on DockerHub](https://hub.docker.com/_/busybox)
* `docker run` with `--init`
  * [Docker docs: Specify an init process](https://docs.docker.com/engine/reference/run/#specify-an-init-process)
  * [SO How to use --init parameter in docker run](https://stackoverflow.com/questions/43122080/how-to-use-init-parameter-in-docker-run)
  * [baseimage-docker (A good explanation of why you'd want to)](https://phusion.github.io/baseimage-docker/)
  * [tini](https://github.com/krallin/tini)
  * [Choosing an init process for multi-process containers](https://ahmet.im/blog/minimal-init-process-for-containers/)
  * [s6](https://skarnet.org/software/s6/index.html)
  * [s6-overlay](https://github.com/just-containers/s6-overlay)
* Installing man pages
  * [How to install man pages on Ubuntu Linux](https://www.cyberciti.biz/faq/how-to-add-install-man-pages-on-ubuntu-linux/)
  * [dpkg-divert(8) - Linux man page](https://linux.die.net/man/8/dpkg-divert)