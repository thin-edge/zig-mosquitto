# zig build for mosquitto

Cross compile mosquitto using zig build (tested with ziglang 0.15.1).

- produce static executables
- support for TLS (with an option to disable it if it is not needed)
- bridge enabled
- no websocket support
- no systemd support (e.g. SDNotify isn't enabled)

## Build Pre-requisites

* ziglang 0.15.1
* [nfpm](https://nfpm.goreleaser.com/) (to build the linux packages)
* wget (used to download the mosquitto source code)

## Building

1. Clone the project

    ```sh
    git clone https://github.com/thin-edge/zig-mosquitto
    cd zig-mosquitto
    ```

2. Checkout/download the mosquitto source code

    ```sh
    just checkout-mosquitto
    ```

    Or you can specify the mosquitto version by setting the `VERSION` environment variable.

    ```sh
    VERSION=2.0.22-1 just checkout-mosquitto
    ```

3. Build all targets

    ```sh
    just build-all
    ```

    Or specify the `VERSION` environment variable.

    ```sh
    VERSION=2.0.22-1 just build-all
    ```

    If you don't want to include TLS, then you can run:

    ```sh
    just build-notls-all
    ```

4. Use the build linux packages under the `dist/` folder

    ```sh
    ls -l dist/

    # Using DNF (Fedora, RHEL, AmazonLinux)
    dnf install tedge-mosquitto*.rpm

    # Using Debian/Ubuntu
    apt-get install tedge-mosquitto*.deb
    ```

### Building a single target

If you don't want to build for all of the targets, then you can build using

The compiled `mosquitto` binary will be created under `./zig-out/mosquitto`, however it will only be the binary from the last build.

**With TLS**

```sh
just build x86_64-linux-musl amd64

just build aarch64-linux-musl arm64

just build arm-linux-musleabihf arm7

just build arm-linux-musleabi arm5

just build riscv64-linux-musl riscv64
```

**Without TLS**

```sh
just build-notls x86_64-linux-musl amd64

just build-notls aarch64-linux-musl arm64

just build-notls arm-linux-musleabihf arm7

just build-notls arm-linux-musleabi arm5

just build-notls riscv64-linux-musl riscv64
```

## TODO

The following items are still yet to be addressed/fixed:

* [ ] Support for other init systems like OpenRC, SysVInit, s6-overlay
