### Cloud build
Build your project in travis-ci(or anywhere with docker) and export results to packagecloud.io

### Usage
Update `travis.yml` with:
```
script:
  - git clone https://github.com/tarantool/build.git
  - ./build/pack/travis.sh
```

travis.yml example:
```yaml
sudo: required
services:
  - docker

language: python
cache: false

env:
    matrix:
      - OS=el DIST=6 PACK=rpm
      - OS=el DIST=7 PACK=rpm
      - OS=fedora DIST=20 PACK=rpm
      - OS=fedora DIST=21 PACK=rpm
      - OS=fedora DIST=22 PACK=rpm
      - OS=fedora DIST=23 PACK=rpm
      - OS=ubuntu DIST=trusty PACK=deb
      - OS=ubuntu DIST=precise PACK=deb
      - OS=ubuntu DIST=vivid PACK=deb
      - OS=debian DIST=jessie PACK=deb
      - OS=debian DIST=wheezy PACK=deb
      - OS=debian DIST=stretch PACK=deb
      - PACK=none

script:
  - git clone https://github.com/tarantool/build.git
  - ./build/pack/travis.sh

notifications:
  email: true
  irc: false

```
Variables:
* OUT_REPO - package cloud repository name(by default=```%username%/%branch%```)
* OS - target operating system (like `fedora` or `ubuntu`)
* DIST - os distribution name or tag (like `21` or `precise`)
* PACK - packager type [deb/rpm/none].

###Additional features
 * automatic rpm and debian spec generation for lua rockspecs

External headers install support:
 * tarantool
 * mysql
 * postgresql

Tests:
If `PACK` is equal `none` - script can run `test.sh` from project root(if file exists)

Exclusion:
It's possible to exclude some builds from packaging:
https://docs.travis-ci.com/user/customizing-the-build/#Build-Matrix

Example: https://github.com/tarantool/tarantool/blob/1.6/.travis.yml


N.B. Now we build packages only for master branch(or for stuff hardcoded in `pack.sh`)

### Packagecloud.io
You must insert packagecloud.io token into travis-ci UI to export packages:
https://packagecloud.io/docs#travis

### Build images
Docker images to build all tarantool projects anywhere. Based in official docker repositories

###Supported platforms
* centos 6
* centos 7
* fedora 20
* fedora 21
* fedora 22
* fedora 23
* debian jessie
* debian wheezy
* debian stretch
* ubuntu precise
* ubuntu trusty
* ubuntu vivid
