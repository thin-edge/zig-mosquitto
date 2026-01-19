set dotenv-load

# package name
PACKAGE_NAME := env("PACKAGE_NAME", "tedge-mosquitto")

# package version
VERSION := env("VERSION", "2.0.22")

# package version release suffix
REVISION := env("REVISION", "1")

# output directory for the linux packages
OUTPUT_DIR := "dist"

# build mosquitto with tls. Accepts either 'true' or 'false'
WITH_TLS := env("WITH_TLS", "true")

# list supported mosquitto versions
list-versions:
    @echo "The following mosquitto versions are supported:"
    @echo
    @ls -c1 build | xargs printf ' * %s\n'
    @echo
    @echo "Reference one of the above versions to build mosquitto:"
    @echo
    @echo "  just VERSION=2.0.18 build"
    @echo

[private]
_build *ARGS='':
    VERSION={{VERSION}} REVISION={{REVISION}} WITH_TLS={{WITH_TLS}} PACKAGE_NAME="{{PACKAGE_NAME}}" goreleaser release --auto-snapshot --skip=announce,publish,validate --clean {{ARGS}}

# build the binary with tls enabled (default)
build *ARGS='':
    WITH_TLS=true just _build

# build the binary without tls enabled
build-notls:
    WITH_TLS=false just PACKAGE_NAME="{{PACKAGE_NAME}}-notls" _build

# build using native zig command (to help with debugging)
build-native *ARGS='':
    cd build/{{VERSION}} && zig build --release=small -Doptimize=ReleaseSmall -DWITH_TLS={{WITH_TLS}} {{ARGS}}
    @echo
    @echo "Build OK. Execute the binary using"
    @echo ""
    @echo "  ./build/{{VERSION}}/zig-out/bin/mosquitto"
    @echo

# clean the distribution folders
clean:
    rm -rf {{OUTPUT_DIR}}

# Publish packages
publish *args="":
    ./ci/publish.sh --path "{{OUTPUT_DIR}}" {{args}}
