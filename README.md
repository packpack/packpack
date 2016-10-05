# PackPack

**PackPack** is a comprehensive ready-to-use solution to build and publish
RPM and Debian packages in the cloud.

[<img src="/doc/logo.png" align="right" width="120px" height="120px" />][PackPack]

* Push your code to [GitHub]

* Build packages using [Travis CI]

* Host repositories on [PackageCloud] or Amazon S3<sup id="a1">[1](#f1)</sup>

**PackPack** is the missing glue between [GitHub], [Travis CI] and
[PackageCloud].

Cloud-hosted and absolutely free of charge.
Just a minute from the push to the end user.

## Supported Distros

* Debian Wheezy / Jessie / Stretch / Sid
* Ubuntu Precise / Trusty / Xenial / Yakkety
* Fedora 23 / 24 / Rawhide
* CentOS 6 / 7

Please feel free to file an [issue][Issues] if you want more distros.

## Quick Start

- Put RPM spec to `rpm/<myreponame>.spec` and Debian rules to `debian/`
  folder.

- Tag the git repository with he `major.minor` annotated git tag.
  PackPack will automatically set `patch` level based on the commit number
  from this tag in order to provide `major.minor.patch` sematic versioning.

```sh
$ git tag -a 1.0
$ git describe --always --long
1.0-0-g5c26e8b # major.minor-patch
```

- Register an account on [PackageCloud] and create a repo.

- Add your [GitHub] project to [Travis CI].

- Add `PACKAGECLOUD_TOKEN=<token>` (secret) and
  `PACKAGECLOUD_REPO=<username>/<reponame>` environment variables
  [to your project settings on Travis CI][Travis CI Environment].

- Enable PackPack magic. Here is our `.travis.yml` file:

```yaml
sudo: required
services:
  - docker

cache: ccache

env:
    matrix:
      - OS=centos DIST=6
      - OS=centos DIST=7
      - OS=fedora DIST=23
      - OS=fedora DIST=24
      - OS=ubuntu DIST=trusty
      - OS=ubuntu DIST=precise
      - OS=ubuntu DIST=xenial
      - OS=ubuntu DIST=yakkety
      - OS=debian DIST=jessie
      - OS=debian DIST=wheezy
      - OS=debian DIST=stretch

script:
  - git clone https://github.com/packpack/packpack.git
  - ./packpack/packpack
```

- Push the update to GitHub repo to trigger Travis CI.

- Check Travis logs and fix the build problems if any.

- Get packages on your [PackageCloud] repo.

- (Optional) Star us on GitHub.

That's it.

## Local Usage

**PackPack** can be used locally without Travis CI to troubleshoot
problems with builds.

Install the following dependencies:

- bash
- tar
- Docker
- Python 2.6+ or Python 3+

Clone this repository:

    myproject$ git clone https://github.com/packpack/packpack.git packpack

Try to build some packages, say RPM packages for Fedora 24:

    myproject$ OS=fedora DIST=24 ./packpack/packpack

For the first time PackPack will download Docker images, please wait
for a while.

Generated RPM packages will be stored to
`packpack/root/${PRODUCT}/${VERSION}-${RELEASE}/$OS/$DIST/results/`
folder:

    myproject$ ls -1s build/root/myproject/1.0.2-0/fedora/24/results/
    total 112
    76 myproject-1.0.2-0.fc24.src.rpm
    36 myproject-devel-1.0.2-0.fc24.x86_64.rpm

## Configuration

**PackPack** settings can be overriden using environment variables.
The most important options are:

* `OS` - target operating system (e.g. `fedora` or `ubuntu`)
* `DIST` - target distribution name or tag (e.g `24` or `precise`)
* `PRODUCT` - the name of software product, used for source tarball and
   source package (e.g. `tarantool`).
* `PACKAGECLOUD_TOKEN` - a secure token for [PackageCloud]
* `PACKAGECLOUD_REPO` - repository name for [PackageCloud]
   (default is `<username>/<branch>`)

See the full list of available options and detailed configuration guide in
[config.yml][config.yml].

## Customization

**PackPack** is fully customizable and extensible.

To override some PackPack rules, create a file named `.packpack.yml`
at the root directory of your git repository. PackPack will load this file
and override system-wide configuration options and rules from
[config.yml][config.yml].

For example, to use a custom versioning for your project, create
`.packpack.yml` file with the following content:

```
env:
  VERSION:
    - git describe --long --always | sed -n 's/^\([0-9\.]*\)-\([0-9]*\)-\([a-z0-9]*\)/\1.\2/p')
  RELEASE=1
```

Please see [config.yml][config.yml] for advanced examples.

### Extension

**PackPack's** [configuration file][config.yml] works like a Makefile on
steroids. By default, PackPack executes tasks in the following order:
`clean` => `tarball` => `build` => `upload`.

It's possible to add custom tasks to your `.packpack.yml` and execute
them thought PackPack. For instance, if you want to collect the code
coverage information for a C/C++ project, create `.packpack.yml` file
with the following content:

```
tasks:
  coverage:
   - cmake . -DWITH_GCOV=ON # enable code coverage analysis
   - make -j # compile
   - make test # run tests
   - ${BUILD_DIR}/tools/coverage upload # upload results coveralls.io
```

Run `./packpack/packpack coverage` or `TASK=coverage ./packpack/packpack`
to execute the new task. `TASK` environment variable is very useful to
to override default target name on [Travis CI].
Here is `.travis.yml` for example above:

```yaml
sudo: required
services:
  - docker

cache: ccache

env:
    matrix:
      - OS=centos DIST=6
      - OS=centos DIST=7
      <cut>
      - TASK=coverage
```

It's possible to exclude some builds from packaging on Travis CI:
https://docs.travis-ci.com/user/customizing-the-build/#Build-Matrix

Example: https://github.com/tarantool/tarantool/blob/1.7/.travis.yml

See Also
--------

* [Tarantool](http://github.com/tarantool/tarantool)
* Tarantool Repositories on [PackageCloud](https://packagecloud.io/tarantool/1_6)

<b id="f1">1</b> Amazon S3 support is coming soon. [^](#a1)
[PackPack]: https://github.com/packpack/packpack
[GitHub]: https://github.com/
[PackageCloud]: https://packagecloud.io/
[Travis CI]: https://travis-ci.org/
[Travis CI Environment]: https://docs.travis-ci.com/user/environment-variables/#Defining-Variables-in-Repository-Settings
[Issues]: https://github.com/packpack/packpack/issues
[RPM]: https://github.com/tarantool/modulekit/tree/master/rpm
[Debian]: https://github.com/tarantool/modulekit/tree/master/debian
[Travis Integration]: https://docs.travis-ci.com/user/getting-started/
[PackageCloud Integration]: https://packagecloud.io/docs#travis
[luafun]: https://github.com/rtsisyk/luafun
[luafun-logo]: https://gist.githubusercontent.com/rtsisyk/28436ebd7bec8cb1a441faf0cc588fb3/raw/7870cfc5d8174041f2abfe12778bb0466e39711e/luafun.png
[tarantool-logo]: https://gist.githubusercontent.com/rtsisyk/28436ebd7bec8cb1a441faf0cc588fb3/raw/bac8cf73fb98ce892a5b3837627736ceaba37652/tarantool.png
[config.yml]: https://github.com/packpack/packpack/blob/master/config.yml
