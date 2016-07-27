# Cloud Build Infrastructure

Build DEB and RPM packages for your project using Docker (on Travis CI)
and export results to [PackageCloud].

Just a minute from the push to packages!

## Prerequisites

- Docker, GNU `make` and `bash` (or just use Travis CI)
- [RPM] spec should be placed to `rpm/${myreponame}.spec` and
  [Debian] rules to `debian/`, respectively:

## Sanity checks
```sh
$ cd mypproject/
myproject$ [ -f rpm/myproject.spec  ] && echo "RPM spec exists"
RPM spec exists
myproject$ [ -f debian/rules ] && echo "Debian rules exists"
Debian rules exists
```

## Usage on Travis

Add to `.travis.yml`:

```yaml
sudo: required
services:
  - docker

cache: ccache

env:
    matrix:
      - OS=centos DIST=6 PACK=rpm
      - OS=centos DIST=7 PACK=rpm
      - OS=fedora DIST=22 PACK=rpm
      - OS=fedora DIST=23 PACK=rpm
      - OS=fedora DIST=24 PACK=rpm
      - OS=fedora DIST=rawhide PACK=rpm
      - OS=ubuntu DIST=trusty PACK=deb
      - OS=ubuntu DIST=precise PACK=deb
      - OS=ubuntu DIST=wily PACK=deb
      - OS=ubuntu DIST=xenial PACK=deb
      - OS=debian DIST=jessie PACK=deb
      - OS=debian DIST=wheezy PACK=deb
      - OS=debian DIST=stretch PACK=deb
      - OS=debian DIST=sid PACK=deb
      - PACK=none

script:
  - git clone https://github.com/tarantool/build.git
  - ./build/pack/travis.sh

notifications:
  email: true
  irc: false

```

Enable [Travis integration] and [Packagecloud integration ] and then push
changes to [GitHub].

N.B. Now we build packages only for master branch (or for stuff hardcoded in
`build/travis/travis.sh`)

### Available ENV variables:

* `OS` - target operating system (like `fedora` or `ubuntu`)
* `DIST` - os distribution name or tag (like `21` or `precise`)
* `PACK` - packager type [deb/rpm/none].
* `PACKAGECLOUD_TOKEN` - a token for http://packagecloud.io/
* `PACKAGECLOUD_REPO` - package cloud repository name (default is ```${username}/${branch}```)

### Tests

If `PACK` is equal `none` - Travis run `test.sh` from project root
(if file exists)

### Exclusion

It's possible to exclude some builds from packaging:
https://docs.travis-ci.com/user/customizing-the-build/#Build-Matrix

Example: https://github.com/tarantool/tarantool/blob/1.6/.travis.yml

## Local Usage

Clone this repository:

    myproject$ git clone https://github.com/tarantool/build.git build

Try to build some packages, say RPM packages for Fedora Rawhide:

    myproject$ ./build/build PRODUCT=tarantool fedora-rawhide

Please wait a while for the first time until Docker downloads images from
Docker Hub. It is possible to get into the cache all supported distros
using `./build/build download` command.

Generated RPM packages will be stored to `build/root/$OS-$PACK-$DIST/results/`
folder:

    myproject$ ls -1s build/root/rpm-fedora-rawhide/results/
    total 112
    76 myproject-1.0.2-0.fc24.src.rpm
    36 myproject-devel-1.0.2-0.fc24.x86_64.rpm

### Targets

* `./build/build` without arguments starts packaging for all supported distros
* `./build/build clean` - clean buildroot (./build/root/)
* `./build/build download` - download images from Docker Hub
* `./build/build tarball`
* `./build/build ${OS}-${DIST}` - build packages for ${OS}-${DIST}, e.g.
  debian-sid, fedora23 or centos7
* `./build/build all` - build all packages

### Available ENV variables

* `PRODUCT` - project name used for source tarball and source package.
* `VERSION` - a package version to use, e.g. 1.0.0 (defaults to git tag name)
* `RELEASE` - a package release number, e.g. -155 (defaults to the commit
   number from the last tag, see `git describe --long`)
* `TARBALL` - tarball name (default is `${PRODUCT}-${VERSION}.tar.gz`)
* `DEB_VERSION` - override the version only for DEB packages
* `DEB_RELEASE` - override the release only for DEB packages
* `RPM_VERSION` - override the version only for RPM packages
* `RPM_RELEASE` - override the release only for RPM packages
* `RPM_SPEC` - a relative path to RPM spec file (default is
   `rpm/${PRODUCT}.spec`)

## Parallelism

`./build/build` is a regular `Makefile`, so it fully supports [parallel
execution] provided by GNU `make`. The command below executes packaging for
`xenial` and `willy` at once:

    ./build/build PRODUCT=tarantool ubuntu-xenial ubuntu-willy -j2

It is also possible to build packages for supported distors in parallel:

    ./build/build PRODUCT=tarantool -j

Please refer to GNU `make` [documentation](parallel execution) for additional
information.

[parallel execution]: https://www.gnu.org/software/make/manual/html_node/Parallel.html

`dpkg-buildpackage` and `rpmbuild` themself also utilize multiple cores
inside of Docker containers. Please control the number of cores used by
the host `make` carefully.

### Customizing

To override some `make` variables create a file named `.build.mk` in the root
of your repository. `./build/build` tries to include this file
before executing any rules. An example of `.build.mk`:

```
# Override version
VERSION=$(shell cat VERSION | sed -n 's/^\([0-9\.]*\)-\([0-9]*\)-\([a-z0-9]*\)/\1.\2/p')
RELEASE=1
```

It is also possible to override variables for specific product by placing
the same file to `./product.d/$(PRODUCT)` in this repository.

See Also
--------

* [Tarantool](http://github.com/tarantool/tarantool)
* Tarantool Repositories on [PackageCloud](https://packagecloud.io/tarantool/1_6)

[PackageCloud]: https://packagecloud.io/
[RPM]: https://github.com/tarantool/modulekit/tree/master/rpm
[Debian]: https://github.com/tarantool/modulekit/tree/master/debian
[GitHub]: https://github.com/
[Travis Integration]: https://docs.travis-ci.com/user/getting-started/
[PackageCloud Integration]: https://packagecloud.io/docs#travis
