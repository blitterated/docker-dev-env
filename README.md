# Docker Dev Environment

I'm not so worried about a single process running isolated in Docker as I am having an isolated filesystem that is unpolluted with dependencies and runtimes from other projects. In return, neither can this isolated filesystem pollute the filesystem of the host OS.

## Intent
* This concept is not for creating containers ready for production deployment. Instead the intent is to code without polluting the developer's machine, and to deploy the project to a production runtime that is not container based. It's simply another way to achieve a deeper kind of segregation along the lines of `virtualenv` or `bundle install--local`.

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

## Access github via ssh

### Generate an ssh key for github

```sh
ssh-keygen -t ed25519 -C "git@blitterated.com"
```

### Add an entry to ~/.ssh/config

```
Host ghblit
  ForwardAgent yes
  Hostname github.com
  User git
  IdentityFile /Users/peteyoung/.ssh/id_ed25519
```

### Test connection

Be sure you've added the public key to github first

```
ssh -T git@ghblit
```

### Add the remote

```
git remote add origin git@ghblit:blitterated/docker_dev_env.git
```

### Push commits for first time

```
git push -u origin master
```


## Create an Ubuntu Docker image

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
FROM ubuntu

MAINTAINER blitterated blitterated@protonmail.com

COPY bash_profile /root/.bash_profile
COPY bashrc /root/.bashrc
COPY provision.sh /root/provision.sh

RUN /root/provision.sh
EOF
```

### Build the docker-dev-env image from Dockerfile

```sh
docker build -t dde .
```

### Run the docker-dev-env image

```sh
docker run -it --rm --init dde /bin/bash
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

Success! All that's left now is to install some manpages. Let's try again in a new container.

### more confusing issues ensued

```sh
apt update
apt install dialog manpages manpages-dev manpages-posix manpages-posix-dev man-db
rm -f /usr/bin/man
dpkg-divert --quiet --remove --rename /usr/bin/man
rm -f /usr/share/man/man1/sh.1.gz
dpkg-divert --quiet --remove --rename /usr/share/man/man1/sh.1.gz
```

```sh
man man
```

```
No manual entry for man
```

Uhh... what? Maybe try indexing the manpages.

```sh
mandb
```

```
...
0 man subdirectories contained newer manual pages.
0 manual pages were added.
0 stray cats were added.
0 old database entries were purged.
```

Are manpages installed?

```sh
dpkg -l manpages
```

```
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name           Version      Architecture Description
+++-==============-============-============-===========================================
ii  manpages       5.05-1       all          Manual pages about using a GNU/Linux system
```

`ii ` in the first column means manpages are installed. Where are those files in the package supposed to land?

```sh
dpkg -L manpages
```

```
/.
/usr
/usr/share
/usr/share/doc
/usr/share/doc/manpages
/usr/share/doc/manpages/Changes.old.gz
/usr/share/doc/manpages/POSIX-MANPAGES
/usr/share/doc/manpages/README.Debian
/usr/share/doc/manpages/TODO.Debian
/usr/share/doc/manpages/changelog.Debian.gz
/usr/share/doc/manpages/copyright
/usr/share/doc/manpages/man-addons.el
/usr/share/doc/manpages/man-pages-5.05.Announce
/usr/share/lintian
/usr/share/lintian/overrides
/usr/share/lintian/overrides/manpages
/usr/share/man
/usr/share/man/man1
/usr/share/man/man1/getent.1.gz
/usr/share/man/man1/iconv.1.gz
/usr/share/man/man1/intro.1.gz
/usr/share/man/man1/ldd.1.gz
/usr/share/man/man1/locale.1.gz
/usr/share/man/man1/localedef.1.gz
/usr/share/man/man1/memusage.1.gz
/usr/share/man/man1/memusagestat.1.gz
/usr/share/man/man1/mtrace.1.gz
/usr/share/man/man1/pldd.1.gz
/usr/share/man/man1/sprof.1.gz
/usr/share/man/man2
/usr/share/man/man2/intro.2.gz
/usr/share/man/man3
/usr/share/man/man3/intro.3.gz
/usr/share/man/man4
/usr/share/man/man4/cciss.4.gz
/usr/share/man/man4/console_codes.4.gz
/usr/share/man/man4/cpuid.4.gz
/usr/share/man/man4/dsp56k.4.gz
/usr/share/man/man4/full.4.gz
/usr/share/man/man4/fuse.4.gz
/usr/share/man/man4/hd.4.gz
/usr/share/man/man4/hpsa.4.gz
/usr/share/man/man4/initrd.4.gz
/usr/share/man/man4/intro.4.gz
/usr/share/man/man4/lirc.4.gz
/usr/share/man/man4/loop.4.gz
/usr/share/man/man4/lp.4.gz
/usr/share/man/man4/mem.4.gz
/usr/share/man/man4/mouse.4.gz
/usr/share/man/man4/msr.4.gz
/usr/share/man/man4/null.4.gz
/usr/share/man/man4/pts.4.gz
/usr/share/man/man4/ram.4.gz
/usr/share/man/man4/random.4.gz
/usr/share/man/man4/rtc.4.gz
/usr/share/man/man4/sd.4.gz
/usr/share/man/man4/smartpqi.4.gz
/usr/share/man/man4/st.4.gz
/usr/share/man/man4/tty.4.gz
/usr/share/man/man4/ttyS.4.gz
/usr/share/man/man4/vcs.4.gz
/usr/share/man/man4/veth.4.gz
/usr/share/man/man4/wavelan.4.gz
/usr/share/man/man5
/usr/share/man/man5/acct.5.gz
/usr/share/man/man5/charmap.5.gz
/usr/share/man/man5/core.5.gz
/usr/share/man/man5/dir_colors.5.gz
/usr/share/man/man5/elf.5.gz
/usr/share/man/man5/filesystems.5.gz
/usr/share/man/man5/gai.conf.5.gz
/usr/share/man/man5/group.5.gz
/usr/share/man/man5/host.conf.5.gz
/usr/share/man/man5/hosts.5.gz
/usr/share/man/man5/hosts.equiv.5.gz
/usr/share/man/man5/intro.5.gz
/usr/share/man/man5/issue.5.gz
/usr/share/man/man5/locale.5.gz
/usr/share/man/man5/motd.5.gz
/usr/share/man/man5/networks.5.gz
/usr/share/man/man5/nologin.5.gz
/usr/share/man/man5/nss.5.gz
/usr/share/man/man5/nsswitch.conf.5.gz
/usr/share/man/man5/proc.5.gz
/usr/share/man/man5/protocols.5.gz
/usr/share/man/man5/repertoiremap.5.gz
/usr/share/man/man5/resolv.conf.5.gz
/usr/share/man/man5/rpc.5.gz
/usr/share/man/man5/securetty.5.gz
/usr/share/man/man5/services.5.gz
/usr/share/man/man5/shells.5.gz
/usr/share/man/man5/slabinfo.5.gz
/usr/share/man/man5/sysfs.5.gz
/usr/share/man/man5/termcap.5.gz
/usr/share/man/man5/ttytype.5.gz
/usr/share/man/man5/tzfile.5.gz
/usr/share/man/man5/utmp.5.gz
/usr/share/man/man6
/usr/share/man/man6/intro.6.gz
/usr/share/man/man7
/usr/share/man/man7/address_families.7.gz
/usr/share/man/man7/aio.7.gz
/usr/share/man/man7/armscii-8.7.gz
/usr/share/man/man7/arp.7.gz
/usr/share/man/man7/ascii.7.gz
/usr/share/man/man7/attributes.7.gz
/usr/share/man/man7/boot.7.gz
/usr/share/man/man7/bootparam.7.gz
/usr/share/man/man7/bpf-helpers.7.gz
/usr/share/man/man7/capabilities.7.gz
/usr/share/man/man7/cgroup_namespaces.7.gz
/usr/share/man/man7/cgroups.7.gz
/usr/share/man/man7/charsets.7.gz
/usr/share/man/man7/complex.7.gz
/usr/share/man/man7/cp1251.7.gz
/usr/share/man/man7/cp1252.7.gz
/usr/share/man/man7/cpuset.7.gz
/usr/share/man/man7/credentials.7.gz
/usr/share/man/man7/ddp.7.gz
/usr/share/man/man7/environ.7.gz
/usr/share/man/man7/epoll.7.gz
/usr/share/man/man7/fanotify.7.gz
/usr/share/man/man7/feature_test_macros.7.gz
/usr/share/man/man7/fifo.7.gz
/usr/share/man/man7/futex.7.gz
/usr/share/man/man7/glob.7.gz
/usr/share/man/man7/hier.7.gz
/usr/share/man/man7/hostname.7.gz
/usr/share/man/man7/icmp.7.gz
/usr/share/man/man7/inode.7.gz
/usr/share/man/man7/inotify.7.gz
/usr/share/man/man7/intro.7.gz
/usr/share/man/man7/ip.7.gz
/usr/share/man/man7/ipc_namespaces.7.gz
/usr/share/man/man7/ipv6.7.gz
/usr/share/man/man7/iso_8859-1.7.gz
/usr/share/man/man7/iso_8859-10.7.gz
/usr/share/man/man7/iso_8859-11.7.gz
/usr/share/man/man7/iso_8859-13.7.gz
/usr/share/man/man7/iso_8859-14.7.gz
/usr/share/man/man7/iso_8859-15.7.gz
/usr/share/man/man7/iso_8859-16.7.gz
/usr/share/man/man7/iso_8859-2.7.gz
/usr/share/man/man7/iso_8859-3.7.gz
/usr/share/man/man7/iso_8859-4.7.gz
/usr/share/man/man7/iso_8859-5.7.gz
/usr/share/man/man7/iso_8859-6.7.gz
/usr/share/man/man7/iso_8859-7.7.gz
/usr/share/man/man7/iso_8859-8.7.gz
/usr/share/man/man7/iso_8859-9.7.gz
/usr/share/man/man7/keyrings.7.gz
/usr/share/man/man7/koi8-r.7.gz
/usr/share/man/man7/koi8-u.7.gz
/usr/share/man/man7/libc.7.gz
/usr/share/man/man7/locale.7.gz
/usr/share/man/man7/mailaddr.7.gz
/usr/share/man/man7/man-pages.7.gz
/usr/share/man/man7/man.7.gz
/usr/share/man/man7/math_error.7.gz
/usr/share/man/man7/mount_namespaces.7.gz
/usr/share/man/man7/mq_overview.7.gz
/usr/share/man/man7/namespaces.7.gz
/usr/share/man/man7/netdevice.7.gz
/usr/share/man/man7/netlink.7.gz
/usr/share/man/man7/network_namespaces.7.gz
/usr/share/man/man7/nptl.7.gz
/usr/share/man/man7/numa.7.gz
/usr/share/man/man7/operator.7.gz
/usr/share/man/man7/packet.7.gz
/usr/share/man/man7/path_resolution.7.gz
/usr/share/man/man7/persistent-keyring.7.gz
/usr/share/man/man7/pid_namespaces.7.gz
/usr/share/man/man7/pipe.7.gz
/usr/share/man/man7/pkeys.7.gz
/usr/share/man/man7/posixoptions.7.gz
/usr/share/man/man7/process-keyring.7.gz
/usr/share/man/man7/pthreads.7.gz
/usr/share/man/man7/pty.7.gz
/usr/share/man/man7/random.7.gz
/usr/share/man/man7/raw.7.gz
/usr/share/man/man7/regex.7.gz
/usr/share/man/man7/rtld-audit.7.gz
/usr/share/man/man7/rtnetlink.7.gz
/usr/share/man/man7/sched.7.gz
/usr/share/man/man7/sem_overview.7.gz
/usr/share/man/man7/session-keyring.7.gz
/usr/share/man/man7/shm_overview.7.gz
/usr/share/man/man7/sigevent.7.gz
/usr/share/man/man7/signal-safety.7.gz
/usr/share/man/man7/signal.7.gz
/usr/share/man/man7/sock_diag.7.gz
/usr/share/man/man7/socket.7.gz
/usr/share/man/man7/spufs.7.gz
/usr/share/man/man7/standards.7.gz
/usr/share/man/man7/suffixes.7.gz
/usr/share/man/man7/symlink.7.gz
/usr/share/man/man7/sysvipc.7.gz
/usr/share/man/man7/tcp.7.gz
/usr/share/man/man7/termio.7.gz
/usr/share/man/man7/thread-keyring.7.gz
/usr/share/man/man7/time.7.gz
/usr/share/man/man7/udp.7.gz
/usr/share/man/man7/udplite.7.gz
/usr/share/man/man7/unicode.7.gz
/usr/share/man/man7/units.7.gz
/usr/share/man/man7/unix.7.gz
/usr/share/man/man7/uri.7.gz
/usr/share/man/man7/user-keyring.7.gz
/usr/share/man/man7/user-session-keyring.7.gz
/usr/share/man/man7/user_namespaces.7.gz
/usr/share/man/man7/utf-8.7.gz
/usr/share/man/man7/uts_namespaces.7.gz
/usr/share/man/man7/vdso.7.gz
/usr/share/man/man7/vsock.7.gz
/usr/share/man/man7/x25.7.gz
/usr/share/man/man7/xattr.7.gz
/usr/share/man/man8
/usr/share/man/man8/iconvconfig.8.gz
/usr/share/man/man8/intro.8.gz
/usr/share/man/man8/ld.so.8.gz
/usr/share/man/man8/ldconfig.8.gz
/usr/share/man/man8/sln.8.gz
/usr/share/man/man8/tzselect.8.gz
/usr/share/man/man8/zdump.8.gz
/usr/share/man/man8/zic.8.gz
/usr/share/man/man4/kmem.4.gz
/usr/share/man/man4/loop-control.4.gz
/usr/share/man/man4/port.4.gz
/usr/share/man/man4/ptmx.4.gz
/usr/share/man/man4/urandom.4.gz
/usr/share/man/man4/vcsa.4.gz
/usr/share/man/man4/zero.4.gz
/usr/share/man/man5/attr.5.gz
/usr/share/man/man5/fs.5.gz
/usr/share/man/man5/numa_maps.5.gz
/usr/share/man/man5/procfs.5.gz
/usr/share/man/man5/resolver.5.gz
/usr/share/man/man5/utmpx.5.gz
/usr/share/man/man5/wtmp.5.gz
/usr/share/man/man7/ftm.7.gz
/usr/share/man/man7/glibc.7.gz
/usr/share/man/man7/iso-8859-1.7.gz
/usr/share/man/man7/iso-8859-10.7.gz
/usr/share/man/man7/iso-8859-11.7.gz
/usr/share/man/man7/iso-8859-13.7.gz
/usr/share/man/man7/iso-8859-14.7.gz
/usr/share/man/man7/iso-8859-15.7.gz
/usr/share/man/man7/iso-8859-16.7.gz
/usr/share/man/man7/iso-8859-2.7.gz
/usr/share/man/man7/iso-8859-3.7.gz
/usr/share/man/man7/iso-8859-4.7.gz
/usr/share/man/man7/iso-8859-5.7.gz
/usr/share/man/man7/iso-8859-6.7.gz
/usr/share/man/man7/iso-8859-7.7.gz
/usr/share/man/man7/iso-8859-8.7.gz
/usr/share/man/man7/iso-8859-9.7.gz
/usr/share/man/man7/iso_8859_1.7.gz
/usr/share/man/man7/iso_8859_10.7.gz
/usr/share/man/man7/iso_8859_11.7.gz
/usr/share/man/man7/iso_8859_13.7.gz
/usr/share/man/man7/iso_8859_14.7.gz
/usr/share/man/man7/iso_8859_15.7.gz
/usr/share/man/man7/iso_8859_16.7.gz
/usr/share/man/man7/iso_8859_2.7.gz
/usr/share/man/man7/iso_8859_3.7.gz
/usr/share/man/man7/iso_8859_4.7.gz
/usr/share/man/man7/iso_8859_5.7.gz
/usr/share/man/man7/iso_8859_6.7.gz
/usr/share/man/man7/iso_8859_7.7.gz
/usr/share/man/man7/iso_8859_8.7.gz
/usr/share/man/man7/iso_8859_9.7.gz
/usr/share/man/man7/latin1.7.gz
/usr/share/man/man7/latin10.7.gz
/usr/share/man/man7/latin2.7.gz
/usr/share/man/man7/latin3.7.gz
/usr/share/man/man7/latin4.7.gz
/usr/share/man/man7/latin5.7.gz
/usr/share/man/man7/latin6.7.gz
/usr/share/man/man7/latin7.7.gz
/usr/share/man/man7/latin8.7.gz
/usr/share/man/man7/latin9.7.gz
/usr/share/man/man7/precedence.7.gz
/usr/share/man/man7/re_format.7.gz
/usr/share/man/man7/svipc.7.gz
/usr/share/man/man7/tis-620.7.gz
/usr/share/man/man7/url.7.gz
/usr/share/man/man7/urn.7.gz
/usr/share/man/man7/utf8.7.gz
/usr/share/man/man8/ld-linux.8.gz
/usr/share/man/man8/ld-linux.so.8.gz
```

Looks like lots of file across `/usr/share/man/` from `man1` through `man8`. 

Here's what it would look like if manpages were not installed

```
root@abf0140a058c:/# dpkg -l manpages
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name           Version      Architecture Description
+++-==============-============-============-=================================
un  manpages       <none>       <none>       (no description available)

root@abf0140a058c:/# dpkg -L manpages
dpkg-query: package 'manpages' is not installed
Use dpkg --contents (= dpkg-deb --contents) to list archive files contents.
```

Let's see what's in those directories right now.

```sh
tree /usr/share/man
```

```
/usr/share/man
|-- cs
|   |-- man1
|   |-- man5
|   `-- man8
|-- da
|   |-- man1
|   |-- man5
|   `-- man8
|-- de
|   |-- man1
|   |-- man5
|   `-- man8
|-- es
|   |-- man1
|   |-- man5
|   `-- man8
|-- fr
|   |-- man1
|   |-- man5
|   `-- man8
|-- hu
|   `-- man1
|-- id
|   `-- man1
|-- it
|   |-- man1
|   |-- man5
|   `-- man8
|-- ja
|   |-- man1
|   |-- man5
|   `-- man8
|-- ko
|   `-- man1
|-- man1
|-- man3
|-- man5
|-- man7
|-- man8
|-- nl
|   |-- man1
|   |-- man5
|   `-- man8
|-- pl
|   |-- man1
|   |-- man5
|   `-- man8
|-- pt
|   |-- man1
|   |-- man5
|   `-- man8
|-- ru
|   |-- man1
|   |-- man5
|   `-- man8
|-- sv
|   |-- man1
|   |-- man5
|   `-- man8
|-- tr
|   `-- man1
|-- zh_CN
|   |-- man1
|   |-- man5
|   `-- man8
`-- zh_TW
    `-- man1

67 directories, 0 files
```

There are zero files in that tree.

Permissions were checked. Reinstallation with `apt` was forced. Head was banged against the wall. Eventually, searching Google with "ubuntu minimal install manpages without unminimize" turned up a link to a [GitHub issue with a comment that mentioned the following](https://github.com/docker/for-linux/issues/639#issuecomment-502491698):

> Some `dpkg` exclusion rules are set up to avoid installing manual pages.

And there it was, right up by the top of the `unminimize` script:

```sh
if [ -f /etc/dpkg/dpkg.cfg.d/excludes ] || [ -f /etc/dpkg/dpkg.cfg.d/excludes.dpkg-tmp ]; then
    echo "Re-enabling installation of all documentation in dpkg..."
    if [ -f /etc/dpkg/dpkg.cfg.d/excludes ]; then
        mv /etc/dpkg/dpkg.cfg.d/excludes /etc/dpkg/dpkg.cfg.d/excludes.dpkg-tmp
    fi
...
```

A quick look inside the `/etc/dpkg/dpkg.cfg.d/excludes` file showed that `/usr/share/man` was indeed excluded. You can see it on the line below "Drop all man pages."

```
cat /etc/dpkg/dpkg.cfg.d/excludes

# Drop all man pages
path-exclude=/usr/share/man/*

# Drop all translations
path-exclude=/usr/share/locale/*/LC_MESSAGES/*.mo

# Drop all documentation ...
path-exclude=/usr/share/doc/*

# ... except copyright files ...
path-include=/usr/share/doc/*/copyright

# ... and Debian changelogs
path-include=/usr/share/doc/*/changelog.Debian.*
```

The next step was to edit `/etc/dpkg/dpkg.cfg.d/excludes` and comment out the line with `cat /etc/dpkg/dpkg.cfg.d/excludes`, and then force a reinstall with `apt`.

```sh
# be sure you commented out the exclude first!
apt --reinstall install manpages
```

Try running `man man` again

```sh
man man
```

```
MAN(7)

NAME
       man - macros to format man pages
...
```

That looks good. Let's double check with `tree`

```sh
tree /usr/share/man
```

Suffice to say, it looks much better now.

Here's a nice script to make a script to provision manpages automatically:

```sh
cat <<EOF > provision.sh
#!/bin/bash
apt update
apt --yes upgrade

# remove dpkg exclusion for manpages
apt install sed
sed -e '\|/usr/share/man|s|^#*|#|g' -i /etc/dpkg/dpkg.cfg.d/excludes

# install manpage packages and dependencies
apt --yes install apt-utils dialog manpages manpages-posix man-db

# remove dpkg-divert entries
rm -f /usr/bin/man
dpkg-divert --quiet --remove --rename /usr/bin/man
rm -f /usr/share/man/man1/sh.1.gz
dpkg-divert --quiet --remove --rename /usr/share/man/man1/sh.1.gz
EOF
```

Let's test it out in a new container

```sh
docker run -it --rm --init --mount type=bind,source="$(pwd)",target=/foo
```

```
bash foo/provision.sh
man man
```

Sweet, sweet victory.

Ultimately, I still don't know why `apt` install fails when deleting a file that's been diverted, in this case `/usr/bin/man`. I think that's a deeper exploration than necessary right now. I understand enough to cleanly unwind what's been minimized, and I'm happy to have man pages again.

## Connect to Docker's secret Linux VM

### connect using nsenter1

It's had many names over the years on Mac: boot2docker, Moby, LinuxKit...

```
docker run -it --rm --init --mount type=bind,source="$(pwd)",target=/foo ubuntu bash
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

Or, why using Docker volumes is a bad idea for development. The volumes are stored inside the Linux kernel instance that is the host for all the guest docker kernels, and not via a bind mount to the filesystem of the host OS. Of course if your root OS is Linux, then it will be available on the root filesystem, but it's still technically a folder managed by Docker.

In other words, use a bind mount, not a volume if you want your code accessible to the host OS and the Docker container.


### Create a new volume

```sh
docker volume create my-vol
```

### Setup git and pull a repo down into the volume

#### Mount the volume to a container

```sh
docker run -it --rm --init -v my-vol:/foo ubuntu bash
```

#### Install git

```sh
apt update
apt install git
```


#### Clone a git repo into the volume

```sh
cd /foo
git clone https://github.com/justincormack/nsenter1.git
ls nsenter1
```

#### Exit the container

```sh
exit
```

### View the volume with nsenter1

#### Fire up the nsenter1 container

```sh
docker run -it --rm --privileged --pid=host justincormack/nsenter1
```

#### Peek at where the volume is stored on the Docker Linux VM image

**NOTE:** This is not a container at this point. You've entered the Linux VM where Docker containers are run. This is the intermediary Linux VM that sits between Mac OS and Docker containers.

```sh
ls /var/lib/docker/volumes/my-vol/_data/nsenter1/
```
#### Exit nsenter1

```sh
exit
```


### Bind mount the volume to Mac OS

Yeah, you can't do this. The bind mount would overlay any existing folders on the container. It throws an error anyway.

```sh
mkdir bar
docker run -it --rm --init \
           --mount type=volume,source=my-vol,target=/foo \
           --mount type=bind,source="$(pwd)"/bar,target=/foo \
           ubuntu bash
```

```
docker: Error response from daemon: Duplicate mount point: /foo.
```

# Issues

## Error while using `apk search` with Alpine. 

This was before switching to Arch and then Debian based images.
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
   * [Remote Development using SSH](https://code.visualstudio.com/docs/remote/ssh)
* Linux Kit
  * [GH: linuxkit](https://github.com/linuxkit/linuxkit)
  * [Announcing LinuxKit](https://www.docker.com/blog/introducing-linuxkit-container-os-toolkit/)
  * [busybox on DockerHub](https://hub.docker.com/_/busybox)
* `docker run` with `--init`
  * [Docker docs: Specify an init process](https://docs.docker.com/engine/reference/run/#specify-an-init-process)
  * [SO: How to use --init parameter in docker run](https://stackoverflow.com/questions/43122080/how-to-use-init-parameter-in-docker-run)
  * [baseimage-docker (A good explanation of why you'd want to)](https://phusion.github.io/baseimage-docker/)
  * [tini](https://github.com/krallin/tini)
  * [Choosing an init process for multi-process containers](https://ahmet.im/blog/minimal-init-process-for-containers/)
  * [s6](https://skarnet.org/software/s6/index.html)
  * [s6-overlay](https://github.com/just-containers/s6-overlay)
  * [Docker and the PID 1 zombie reaping problem](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/)
  * [Container cannot connect to Upstart #1024](https://github.com/moby/moby/issues/1024#)
* Installing man pages
  * [How to install man pages on Ubuntu Linux](https://www.cyberciti.biz/faq/how-to-add-install-man-pages-on-ubuntu-linux/)
  * [dpkg-divert(8) - Linux man page](https://linux.die.net/man/8/dpkg-divert)
* SSH forwarding
  * [GH: Generating a new SSH key and adding it to the ssh-agent](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
  * [SO: Using SSH keys inside docker container](https://stackoverflow.com/questions/18136389/using-ssh-keys-inside-docker-container/66301568#66301568)
  * [Build secrets and SSH forwarding in Docker 18.09](https://medium.com/@tonistiigi/build-secrets-and-ssh-forwarding-in-docker-18-09-ae8161d066)
  * [GH: How to SSH agent forward into a docker container](https://gist.github.com/d11wtq/8699521)
  * [Sharing an SSH Agent between a host machine and a Docker container](https://www.jamesridgway.co.uk/sharing-an-ssh-agent-between-a-host-machine-and-a-docker-container/)