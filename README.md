# zig build for mosquitto

Cross compile mosquitto using zig build (tested with ziglang 0.15.1).

- produce static executables
- support for TLS (with an option to disable it if it is not needed)
- bridge enabled
- no websocket support
- no systemd support (e.g. SDNotify isn't enabled)

## Build Pre-requisites

* ziglang 0.15.1
* [just](https://github.com/casey/just) >= 1.15.0
* [goreleaser](https://github.com/goreleaser/goreleaser) >= 2.13 (to coordinate the build and packaging)
* UPX (optional: used to provide self-extracting binaries for devices with very limited file storage)

**Note**

The mosquitto source code is downloaded automatically using the ziglang build system. You can manually download the source code yourself by downloading the url defined in the corresponding the build.zig.zon.

## Building

1. Clone the project

    ```sh
    git clone https://github.com/thin-edge/zig-mosquitto
    cd zig-mosquitto
    ```

2. Build all targets

    ```sh
    just build
    ```

    Or specify the `VERSION` environment variable.

    ```sh
    VERSION=2.0.22 just build
    ```

    If you don't want to include TLS, then you can run:

    ```sh
    just build-notls
    ```

3. Use the build linux packages under the `dist/` folder

    ```sh
    ls -l dist/

    # Using DNF (Fedora, RHEL, AmazonLinux)
    dnf install tedge-mosquitto*.rpm

    # Using Debian/Ubuntu
    apt-get install tedge-mosquitto*.deb
    ```

### Building manually

If you want to experiment with building the binary manually using zig, then use the following commands to build a specific version of mosquitto.

```sh
cd build/{VERSION}
zig build --release=small -Doptimize=ReleaseSmall -DWITH_TLS=true
```

## TODO

The following items are still yet to be addressed/fixed:

* [ ] Support for other init systems like OpenRC, SysVInit, s6-overlay
