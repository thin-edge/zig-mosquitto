# zig build for mosquitto

Cross compile mosquitto using zig build.

- produce static executables
- no support for TLS
- bridge disabled

```shell
# Clone: mainly a build.zig file
$ git clone https://github.com/didier-wenzek/zig-mosquitto
$ cd zig-mosquitto

# The build expect a mosquitto sub-directory with mosquitto sources 
$ wget https://mosquitto.org/files/source/mosquitto-2.0.18.tar.gz
$ tar -xzf mosquitto-2.0.18.tar.gz
$ ln -s mosquitto-2.0.18 mosquitto

# Compile with appropriate target
$ zig build -Doptimize=ReleaseSmall -Dtarget=aarch64-linux-musl
$ ls -l zig-out/bin/mosquitto
-rwxrwxr-x 1 didier didier 209200 juin  19 22:00 zig-out/bin/mosquitto
$ file zig-out/bin/mosquitto
zig-out/bin/mosquitto: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, stripped
```

TODO:

- Mosquitto version should not be hardcoded
- [Build for multiple targets to make a release](https://ziglang.org/learn/build-system/#build-for-multiple-targets-to-make-a-release)
