S6_OVERLAY_VERSION=3.1.0.1

# Using parens with `cd` and `curl` to temporarily change working directory in a subshell.
# This allows us to use `curl` to download to a different directory than the current one.

(cd /tmp && curl -LO "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz")
tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
(cd /tmp && curl -LO "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz")
tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz

rm -rf /tmp/*
