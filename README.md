# scx-tools

Builds a Debian 13 (trixie) amd64 package of
[sched-ext/scx-loader](https://github.com/sched-ext/scx-loader): `scx_loader`, a
D-Bus service that starts and switches sched_ext schedulers on request, and `scxctl`,
its command-line client.

The schedulers themselves, and `scxtui`, are in
[scx-scheds](https://github.com/hmwassim/scx-scheds), which this package depends on.

## Build

Requires Docker.

```sh
./build.sh
```

The package is built in a fresh `debian:trixie` container with `dpkg-buildpackage`
and checked with `lintian`. The result goes to `out/`, for example
`out/scx-tools_1.1.3-2_amd64.deb`.

Rust comes from `trixie-backports`, because upstream needs a newer version than trixie
has. Crates are downloaded with `cargo fetch --locked` before the build, and the build
itself runs offline (`--frozen`).

## New release

The version in `debian/changelog` decides which upstream tag is built. The upstream
part of `1.1.4-1` is `1.1.4`, so the tag `v1.1.4` is built:

```sh
dch -v 1.1.4-1 "Package scx-loader 1.1.4."
./build.sh
```

To rebuild the same upstream version with packaging changes, bump only the revision
(`1.1.4-2`). Releases are tagged with the full version, `v1.1.4-1`.

## Install

```sh
sudo apt install ./out/scx-scheds_*.deb ./out/scx-tools_*.deb
```

`scx_loader` is started on demand by D-Bus: `scxctl start --sched bpfland`. To start a
scheduler at boot, set `default_sched` in `/etc/scx_loader.toml` (copy it from
`/usr/share/scx_loader/config.toml`) and run `sudo systemctl enable scx_loader`.

The kernel runs only one sched_ext scheduler at a time, so don't also enable
`scx.service` from scx-scheds.

License texts for the bundled Rust crates are in
`/usr/share/doc/scx-tools/THIRD-PARTY-LICENSES.gz`.

Earlier releases are in
[scx-bundler](https://github.com/hmwassim/scx-bundler).
