#!/bin/sh
set -eu

PKG='scx-tools'
REPO='https://github.com/sched-ext/scx-loader.git'
IMAGE='debian:trixie'

inside() {
   export DEBIAN_FRONTEND=noninteractive

   # Installing build dependencies, Rust from backports (upstream needs >= 1.91)
   echo deb http://deb.debian.org/debian trixie-backports main \
      >/etc/apt/sources.list.d/backports.list
   apt-get update
   apt-get install -y --no-install-recommends \
      build-essential lintian git ca-certificates
   apt-get install -y --no-install-recommends -t trixie-backports cargo rustc
   apt-get build-dep -y --no-install-recommends /src

   version="$(dpkg-parsechangelog -l /src/debian/changelog -S Version)"
   upstream="${version%-*}"

   echo "Fetching [$PKG v$upstream]..."
   rm -rf "/build/$PKG"
   git clone --depth 1 --branch "v$upstream" "$REPO" "/build/$PKG"
   cp -r /src/debian "/build/$PKG/debian"

   cd "/build/$PKG"
   CARGO_HOME="/build/$PKG/debian/cargo-home" cargo fetch --locked

   echo "Building [$PKG $version]..."
   dpkg-buildpackage -b -us -uc

   deb="/build/${PKG}_${version}_amd64.deb"
   lintian --fail-on error "$deb"

   mkdir -p /src/out
   cp "$deb" /src/out/
   chown "$HOST_UID:$HOST_GID" /src/out "/src/out/$(basename "$deb")"
   echo "Done [out/$(basename "$deb")]"
}

if [ "${1:-}" = '--inside' ]; then
   inside
   exit 0
fi

[ $# -eq 0 ] || { echo "usage: $0" >&2; exit 2; }

cd "$(dirname "$0")"

# Removing the container on Ctrl-C, docker run alone leaves it running
container="$PKG-build-$$"
trap 'docker rm -f "$container" >/dev/null 2>&1; exit 130' INT TERM

docker run --rm --name "$container" \
   -v "$PWD:/src" \
   -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
   "$IMAGE" /src/build.sh --inside
