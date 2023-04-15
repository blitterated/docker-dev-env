set -e

#S6_OVERLAY_VERSION=3.1.2.1
S6_OVERLAY_VERSION=3.1.4.2

get_arch() {
  ARCH="$(uname -m)"

  case $ARCH in
    "x86_64" )
      echo x86_64
      ;;
    "arm64" | "aarch64" )
      echo aarch64
      ;;
    * )
      >&2 echo Architecture \"$ARCH\" not implemented for s6 provisioning
      exit 1
  esac
}

download_and_expand_archive() {
  TARBALL=$1

  S6_OVERLAY_DOWNLOAD_PATH="https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}"

  # We're using parens with `cd` and `curl` to temporarily do work in a different directory using a subshell.
  # This allows us to use `curl` to download to a different directory than the current one. Thurl.

  (cd /tmp && curl -LO "${S6_OVERLAY_DOWNLOAD_PATH}/${TARBALL}")
  tar -C / -Jxpf /tmp/$TARBALL
}

# Determine which architecture to download s6 for. Die if no match found.
S6_ARCH=$(get_arch)

download_and_expand_archive "s6-overlay-${S6_ARCH}.tar.xz"
download_and_expand_archive "s6-overlay-noarch.tar.xz"

rm -rf /tmp/*
