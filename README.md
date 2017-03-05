# PackPack

[![Travis][travis-badge]][travis-url]
[![License][license-badge]][license-url]
[![RPM Packages][rpm-badge]][rpm-url]
[![Debian Packages][deb-badge]][deb-url]
[![Demo Video][demo-badge]][demo-url]

[<img src="/doc/logo.png" align="right" width="180px" height="180px" />][PackPack]

**PackPack** is a simple tool to build RPM and Debian packages from **git**
repositories:

* Fast reproducible builds using Docker containers

* Semantic versioning based on annotated git tags

* Support for all major Linux distributions as targets

**PackPack** works best with [GitHub], [Travis CI] and [PackageCloud]:

* Push your code to [GitHub]

* Build packages using [Travis CI]

* Host repositories on [PackageCloud]

[Watch a demonstration][demo-url] of PackPack.

## Motivation

**PackPack** is designed by folks from [Mail.Ru Group], a leading
Internet company in Europe, to automate release management cycle of
open source products as well as of proprietary software.

**[Tarantool]**, an open-source general-purpose database and an application
server, has dozens of git commits per day and this number is constantly
increasing month after month. In order to deliver the best user experience
and offer enterprise-level support quality, the Tarantool team packages
almost every git commit from four git branches for (!) fifteen various
Linux distribution.

**Traditional tools**, like `mock` and `pbuilder`, were tremendously slow and
ridiculously overcomplicated. Customers **had to wait hours** for hotfix
packages and the project paid thousands of dollars annually for hardware and
electricy bills. Such cost are unacceptable for the most "free as in speech"
open-source projects.

**PackPack** has reduced __push-to-package__ time **from hours to minutes**.
Tarantool team were even able to package all complementary modules,
addons and connectors using this tool. Tarantool users now can also package
their own proprietary modules in the same manner as official packages.

## Our Users

* [Tarantool] - general-purpose database and Lua application server.
* [IronSSH] - secure end-to-end file transfer software developed by
  [IronCore Labs](https://ironcorelabs.com/).
* [MINC Toolkit V2] - Medical Imaging NetCDF Toolkit developed by
   [McConnell Brain Imaging Centre](https://www.mcgill.ca/bic/home).
* [LuaFun] - functional programming library for Lua.
* [MsgPuck] - simple and efficient MsgPack binary serialization library.
* [Phalcon] - high performance PHP Framework.

Of course, [PackPack] itself is packaged using [PackPack].

## Supported Platforms

Distributions:

* Debian Wheezy / Jessie / Stretch / Sid
* Ubuntu Precise / Trusty / Xenial / Yakkety / Zesty
* Fedora 24 / 25 / Rawhide
* CentOS 6 / 7

Archictectures:

* `i386`
* `x86_64`
* `armhf` (32-bit ARM with hardware floating-point)
* `aarch64` (64-bit ARM)

The actual list of distribution is available on [Docker Hub]
(https://hub.docker.com/r/packpack/packpack/tags/).
Please file an [issue][Issues] if you want more.

## Getting Started

- Install `git`, `docker` and any posix-compatible shell
  (bash, dash, zsh, etc.).
  The complicated one is Docker, please see the detailed guide on
  [docs.docker.com web-site][Docker Installation Guide].

- Add RPM `spec` to `rpm/` folder of your git repository. The best way to
  create a new `spec` file for your product is to find an existing one for
  a similar software, rename and then modify it. See [Fedora Git] and
  [Fedora Packaging Guidelines] for details. Some examples are available
  from [tarantool/modulekit][ModuleKit] repository.

- Add `debian/` folder to your git repository, as usual. Debian has
  complicated package structure and we strongly recommend to find a similar
  package in the [official repositories][Debian Packages],
  download it using `apt-get source package` command, copy and paste and
  then modify `debian/` directory. Some examples are available from
  [tarantool/modulekit][ModuleKit] repository.

- Create an **annotated** `major.minor` git tag in your repository.
  PackPack will automatically set `patch` level based on the commit number
  from this tag in order to provide `major.minor.patch` semantic versioning:

```sh
$ git tag -a 1.0
$ git describe --always --long
1.0-0-g5c26e8b # major.minor-patch = 1.0-0
$ git push origin 1.0:1.0 # Push to GitHub
```

- Clone PackPack repository:

```sh
myproject$ git clone https://github.com/packpack/packpack.git packpack
```

- Try to build some packages for, say, Fedora 24. For the first time,
  Docker will download images from Docker Hub, please wait a little bit.

```sh
myproject$ OS=fedora DIST=24 ./packpack/packpack
```

- The build artifacts will be stored into `build/` directory:

```sh
myproject$ ls -1s build/
total 112
76 myproject-1.0.2-0.fc24.src.rpm
36 myproject-devel-1.0.2-0.fc24.x86_64.rpm
```

Of course, PackPack can also be installed from DEB/RPM packages:

```sh
# For Debian, Ubuntu and other Debian-based
curl -s https://packagecloud.io/install/repositories/packpack/packpack/script.deb.sh | sudo bash
# For Fedora, RedHat, CentOS and other RPM-based
curl -s https://packagecloud.io/install/repositories/packpack/packpack/script.rpm.sh | sudo bash
```

See [PackPack Repositories] for additional instructions.

## How it Works

PackPack performs the following steps:

- A Docker container is started using `packpack/packpack:$OS$DIST` image.

- The source repository is mounted to the container as a read-only volume.

- `major.minor.patch` version is extracted from `git describe` output.

- A source tarball (`product-major.minor.patch.tar.gz`) is packed from
  files added to git repository.

- For RPM package:

  + `spec` file is copied from `rpm/`, `Version:` tag is updated
     according to extracted `major.minor.patch` version, `%prep`
     is updated to match the source tarball file name.
  + A source RPM (`product-major.minor.patch-release.dist.src.rpm`) is
    built from the source tarball using generated spec file.
  + BuildRequires are installed using `dnf builddep` or `yum-builddep`.
    Docker images already have a lot of packages pre-installed to speed up
    the build.
  + **rpmbuild** is started to build RPM packages from the source RPM.

- For Debian packages:

  + `debian/changelog` is bumped with extracted `major.minor.patch`
    git version.
  + Build-Depends are installed using `mk-build-deps` tool.
    Docker images already have a lot of packages pre-installed to
    speed up the build.
  + A symlink for orig.tar.gz is created to the source tarball
  + **dpkg-buildpackage** is started to build Debian packages.

- Resulted packages, tarballs and log files are moved to `/build` volume,
  which is mounted by default to `./build` directory of your git repository.

## GitHub, Travis CI and PackageCloud

**PackPack** is designed to use with [GitHub], [Travis CI] and [PackageCloud].

- Register free [PackageCloud] account and create a repository.

- Add your GitHub project to [Travis CI][Travis CI Integration].

- Add the following environment variables
  [to the project settings on Travis CI][Travis CI Environment]:

  + `PACKAGECLOUD_TOKEN=<token>` (secret)
  + `PACKAGECLOD_USER=<username>` (public)
  + `PACKAGECLOUD_REPO=<reponame>` (public)

  [Click to see how][Travis CI Env].

- Enable PackPack magic in `.travis.yml` file:

```yaml
sudo: required
services:
  - docker

cache:
    directories:
     - $HOME/.cache

language: C

env:
    matrix:
      - OS=el DIST=6
      - OS=el DIST=7
      - OS=fedora DIST=24
      - OS=fedora DIST=25
      - OS=ubuntu DIST=trusty
      - OS=ubuntu DIST=precise
      - OS=ubuntu DIST=xenial
      - OS=ubuntu DIST=yakkety
      - OS=debian DIST=jessie
      - OS=debian DIST=wheezy
      - OS=debian DIST=stretch
      - OS=ubuntu DIST=xenial ARCH=i386
      - OS=debian DIST=jessie ARCH=i386

script:
 - git submodule update --init --recursive
 - git describe --long
 - git clone https://github.com/packpack/packpack.git packpack
 - packpack/packpack

deploy:
  # Deploy packages to PackageCloud
  provider: packagecloud
  username: ${PACKAGECLOUD_USER}
  repository: ${PACKAGECLOUD_REPO}
  token: ${PACKAGECLOUD_TOKEN}
  dist: ${OS}/${DIST}
  package_glob: build/*.{deb,rpm}
  skip_cleanup: true
  on:
    branch: master
    condition: -n "${OS}" && -n "${DIST}" && -n "${PACKAGECLOUD_TOKEN}"
```

- Push changes to GitHub repository to trigger Travis CI build.

- Check Travis CI logs and fix packaging problems, if any.
  [Click to see how][Travis CI Example].

- Get packages on your [PackageCloud] repository.
  [Click to see how][PackageCloud example].

- ???

- **Star this project on GitHub** if you like this idea.

- PROFIT

That's it.


BTW, Travis CI [allow to exclude some builds from matrix][Travis CI Matrix],
see an example in [Tarantool GitHub](https://github.com/tarantool/tarantool) repo.

## Configuration

**PackPack** can be configured via environment variables:

* `OS` - target operating system name, e.g. `fedora` or `ubuntu`
* `DIST` - target distribution name, e.g `24` or `xenial`
* `ARCH` - target architecture, like on Docker Hub:
   - `i386`
   - `x86_64`
   - `armhf`
   - `aarch64`
   It is possible to use `ARCH=i386` on `x86_64` host and
   `ARCH=armhf` on `aarch64` host, but there is no way to run ARM images on
   Intel and vice versa. Docker is qemu and can't emulate foreign
   instruction set.
* `BUILDDIR` - a directory used to store intermediate files and resulted
   packages (default is `./build`).
* `PRODUCT` - the name of software product, used for source tarball and
   source package, e.g. `tarantool`
* `VERSION` - semantic version of the software, e.g. 2.4.35
   (default is extracted for `git describe`).
* `RELEASE` - the number of times this version of the software has been
   packaged (default is 1).
*  `TARBALL_COMPRESSOR` - a compression algorithm to use, e.g. gz, bz2, xz
   (default is xz).
* `CHANGELOG_NAME`, `CHANGELOG_EMAIL`, `CHANGELOG_TEXT` - information
   used to bump version in changelog files.
* `DOCKER_REPO` - a Docker repository to use (default is `packpack/packpack`).
* `CCACHE*` - Config variables for ccache, such as CCACHE_DISABLE

See the full list of available options and detailed configuration guide in
[pack/config.mk](pack/config.mk) configuration file.

The actual list of distribution is available on [Docker Hub]
(https://hub.docker.com/r/packpack/packpack/tags/).

## Contribution

**PackPack** is written on Makefiles and contains less than 300 lines of code.
We've tried different variants, like Python, but GNU Make is actually
the simplest (and fastest) one.

**Any pull requests are welcome.**

Please feel free to fork this repository for experiments.
You may need to create your own repository on Docker Hub.
[Click to see how][Docker Hub Example].

## See Also

[Watch a demonstration][demo-url] of PackPack.
Please feel free to contact us if you need some help:

* [Email](mailto:roman@tarantool.org)
* [Google Groups](mailto:tarantool@googlegroups.com)
* [Telegram Channel](http://telegram.me/tarantool)
* [GitHub Issues][Issues]
* [Twitter](https://twitter.com/rtsisyk)

**PackPack** can be installed as a regular system tool from RPM/DEB packages.

Check out [PackPack Repositories] on [PackageCloud].

--------------------------------------------------------------------------------

Please **"Star"** this project on GitHub to help it to survive! Thanks!

[travis-badge]: https://travis-ci.org/packpack/packpack.svg?branch=master
[travis-url]: https://travis-ci.org/packpack/packpack
[license-badge]: https://img.shields.io/badge/License-BSD--2-orange.svg?style=flat
[license-url]: LICENSE
[deb-badge]: https://img.shields.io/badge/Packages-Debian-red.svg?style=flat
[deb-url]: https://packagecloud.io/packpack/packpack?filter=debs
[rpm-badge]: https://img.shields.io/badge/Packages-RPM-blue.svg?style=flat
[rpm-url]: https://packagecloud.io/packpack/packpack?filter=rpms
[demo-badge]: https://img.shields.io/badge/Video-Demo-lightgrey.svg?style=flat
[demo-url]: https://asciinema.org/a/3unm4sw4g889ddk7tr0uettbn

[PackPack]: https://github.com/packpack/packpack
[GitHub]: https://github.com/
[PackageCloud]: https://packagecloud.io/
[Tarantool]: https://tarantool.org/
[Tarantool GitHub]: https://github.com/tarantool/tarantool
[Mail.Ru Group]: https://corp.mail.ru/en/
[IronSSH]: https://github.com/IronCoreLabs/ironssh
[Phalcon]: https://github.com/phalcongelist/packagecloud
[MINC Toolkit v2]: https://github.com/gdevenyi/minc-toolkit-v2
[LuaFun]: https://github.com/rtsisyk/luafun
[MsgPuck]: https://github.com/rtsisyk/msgpuck
[Docker Installation Guide]: https://docs.docker.com/engine/installation/
[Fedora Git]: http://pkgs.fedoraproject.org/cgit/rpms/
[Fedora Packaging Guidelines]: https://fedoraproject.org/wiki/Packaging:Guidelines
[Debian Packages]: http://packages.debian.org/
[ModuleKit]: https://github.com/tarantool/modulekit
[Travis CI]: https://travis-ci.org/
[Travis CI Integration]: https://docs.travis-ci.com/user/getting-started/
[Travis CI Environment]: https://docs.travis-ci.com/user/environment-variables/#Defining-Variables-in-Repository-Settings
[Travis CI Matrix]: https://docs.travis-ci.com/user/customizing-the-build/#Build-Matrix
[Issues]: https://github.com/packpack/packpack/issues
[RPM]: https://github.com/tarantool/modulekit/tree/master/rpm
[Debian]: https://github.com/tarantool/modulekit/tree/master/debian
[PackageCloud Integration]: https://packagecloud.io/docs#travis
[Docker Hub Example]: /doc/dockerhub.png
[Travis CI Env]: /doc/travisenv.png
[Travis CI Example]: /doc/travis.png
[PackageCloud Example]: /doc/packagecloud.png
[Tarantool Download]: https://tarantool.org/download.html
[PackPack Repositories]: https://packagecloud.io/packpack/packpack/install
