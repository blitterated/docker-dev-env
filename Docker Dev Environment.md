# Docker Dev Environment

A curated history of work

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
        man man-pages mdocml-apropos \
        less less-doc \
        bash bash-doc bash-completion \
        curl curl-doc \
        git git-doc \
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

## Connect to Docker's secret Linux VM

### connect using nsenter1

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

Or, why using Docker volumes is a bad idea for development. The volumes are stored inside the Linux kernel instance that is the  host for all the guest docker kernels, and not via a bound volume to the root OS' filesystem. Of course if your root OS is Linux, then you're fine`


### Create a new volume

```sh
```

### Mount the volume to a container

```sh
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