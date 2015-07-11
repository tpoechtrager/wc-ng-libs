WC-NG library build scripts
---------------------------

The offical builds are done this way:

`./common/build_all.sh curl dlfcn-win32 geoip sensors sdl-1.2 sdl-2.0`

What you'll need for the **official** builds:

* A Linux system as host
* Clang with LTO support, preferable 3.6
* [bc2obj](https://github.com/tpoechtrager/bc2obj)
* [wclang](https://github.com/tpoechtrager/wclang) with LTO support (LTO support not public yet - available on request)
* A FreeBSD cross toolchain based on clang with LTO suppport

General requirements:

* bison (sensors)
* automake (geoip)
* wget, openssl (hash check), make, bash, ...

If you just want to do your own private builds for your system,  
then a local system compiler is all you need.

Just run:

`TARGET=<target> <lib>/build.sh`

i.e.:

`TARGET=linux64 geoip/build.sh`

### Supported Targets: ###

* linux32
* linux64
* osx32
* osx64
* ios-armXX (curl / geoip / openssl)
* freebsd64
* mingw32
* mingw64
* w32-clang (wclang)
* w64-clang (wclang)

### Supported Compilers: ###

* gcc
* clang

### Credits: ###

[Some parts](https://bitbucket.org/ogros/buildscripts/commits/all)
were written by 'Glen Masgai'.

### License: ###

The patches found in various library directories have the same license  
as the patched library itself, everything else is GPLv2.
