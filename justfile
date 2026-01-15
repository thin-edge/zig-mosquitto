set dotenv-load

# package name
PACKAGE_NAME := env("PACKAGE_NAME", "tedge-mosquitto")

# package version
VERSION := env("VERSION", "2.0.22-1")

# package version release suffix
REVISION := env("REVISION", "1")

# ziglang build options to control different user options
BUILD_OPTIONS := env("BUILD_OPTIONS", "")

# ziglang target triple
TARGET := env("TARGET", "x86_64-linux-musl")

# nfpm package architecture, this differs from the ziglang target triple
# as packaging generally have their own naming convention, so nfpm needs
# to know how to translate these names to deb, rpm, apk etc.
PACKAGE_TARGET := env("TARGET", "amd64")

# output directory for the linux packages
OUTPUT_DIR := "dist"

# checkout the mosquitto source code
checkout-mosquitto version=VERSION:
    wget https://mosquitto.org/files/source/mosquitto-{{version}}.tar.gz
    tar -xzf mosquitto-{{version}}.tar.gz
    ln -sf mosquitto-{{version}} mosquitto
    rm -f mosquitto-{{version}}.tar.gz

# build the binary without tls
build-notls target=TARGET package_arch=PACKAGE_TARGET:
    zig build -Doptimize=ReleaseSmall -Dtarget={{target}} -Dversion={{VERSION}} {{BUILD_OPTIONS}}
    mkdir -p dist/
    PACKAGE_NAME="{{PACKAGE_NAME}}-notls" REVISION={{REVISION}} VERSION={{VERSION}} ARCH={{package_arch}} nfpm package -p rpm -f ./packaging/nfpm.yaml -t {{OUTPUT_DIR}}/
    PACKAGE_NAME="{{PACKAGE_NAME}}-notls" REVISION={{REVISION}} VERSION={{VERSION}} ARCH={{package_arch}} nfpm package -p apk -f ./packaging/nfpm.yaml -t {{OUTPUT_DIR}}/
    PACKAGE_NAME="{{PACKAGE_NAME}}-notls" REVISION={{REVISION}} VERSION={{VERSION}} ARCH={{package_arch}} nfpm package -p deb -f ./packaging/nfpm.yaml -t {{OUTPUT_DIR}}/

# build the binary with tls enabled (default)
build target=TARGET package_arch=PACKAGE_TARGET:
    zig build -Doptimize=ReleaseSmall -Dtarget={{target}} -Dversion={{VERSION}} -DWITH_TLS=true {{BUILD_OPTIONS}}
    mkdir -p dist/
    PACKAGE_NAME="{{PACKAGE_NAME}}" REVISION={{REVISION}} VERSION={{VERSION}} ARCH={{package_arch}} nfpm package -p rpm -f ./packaging/nfpm.yaml -t {{OUTPUT_DIR}}/
    PACKAGE_NAME="{{PACKAGE_NAME}}" REVISION={{REVISION}} VERSION={{VERSION}} ARCH={{package_arch}} nfpm package -p apk -f ./packaging/nfpm.yaml -t {{OUTPUT_DIR}}/
    PACKAGE_NAME="{{PACKAGE_NAME}}" REVISION={{REVISION}} VERSION={{VERSION}} ARCH={{package_arch}} nfpm package -p deb -f ./packaging/nfpm.yaml -t {{OUTPUT_DIR}}/

# build all targets without tls
build-notls-all:
    just build-notls x86_64-linux-musl amd64
    just build-notls aarch64-linux-musl arm64
    just build-notls arm-linux-musleabihf arm7
    just build-notls arm-linux-musleabi arm5
    just build-notls riscv64-linux-musl riscv64

# build all targets with tls enabled
build-all:
    just build x86_64-linux-musl amd64
    just build aarch64-linux-musl arm64
    just build arm-linux-musleabihf arm7
    just build arm-linux-musleabi arm5
    just build riscv64-linux-musl riscv64

# clean the distribution folders
clean:
    rm -rf {{OUTPUT_DIR}}

# Publish packages
publish *args="":
    ./ci/publish.sh --path "{{OUTPUT_DIR}}" {{args}}
