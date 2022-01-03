# Reverse the removal of manpages done during the Ubuntu
# minimizing process

# comment out dpkg exclusion for manpages
sed -e '\|/usr/share/man|s|^#*|#|g' -i /etc/dpkg/dpkg.cfg.d/excludes

# install manpage packages and dependencies
apt --yes install apt-utils dialog manpages manpages-posix man-db

# remove dpkg-divert entries for manpages
rm -f /usr/bin/man
dpkg-divert --quiet --remove --rename /usr/bin/man
rm -f /usr/share/man/man1/sh.1.gz
dpkg-divert --quiet --remove --rename /usr/share/man/man1/sh.1.gz

apt --yes install less
