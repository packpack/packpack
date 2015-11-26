### Cloud build
Add this repo as submodule to build your project in travis-ci(or anywhere with docker) and export results to packagecloud.io

### Usage
1. Add `build` as submodule
2. Add `.travis.yml`
3. Add `build.sh` script(special for rpm)

travis.yml example: need to enable docker config and build-matrix
```yaml
sudo: required
services:
  - docker

language: c
compiler:
    - gcc

env:
    global:
      - OUT_REPO=username/test-repo
    matrix:
      - OS=el DIST=6 PACK=rpm
      - OS=el DIST=7 PACK=rpm
      - OS=fedora DIST=20 PACK=rpm
      - OS=fedora DIST=21 PACK=rpm
      - OS=fedora DIST=22 PACK=rpm
      - OS=fedora DIST=23 PACK=rpm
      - OS=ubuntu DIST=trusty PACK=deb PROD=tarantool-c P_URI=https://github.com/tarantool/tarantool-c.git
      - OS=ubuntu DIST=precise PACK=deb PROD=tarantool-c P_URI=https://github.com/tarantool/tarantool-c.git
      - OS=ubuntu DIST=vivid PACK=deb PROD=tarantool-c P_URI=https://github.com/tarantool/tarantool-c.git
      - OS=debian DIST=jessie PACK=deb PROD=tarantool-c P_URI=https://github.com/tarantool/tarantool-c.git
      - OS=debian DIST=wheezy PACK=deb PROD=tarantool-c P_URI=https://github.com/tarantool/tarantool-c.git
      - OS=debian DIST=stretch PACK=deb PROD=tarantool-c P_URI=https://github.com/tarantool/tarantool-c.git
      - PACK=none

```
Variables:
* OUT_REPO - package cloud repository name
* OS - target operating system
* DIST - os distribution name or tag (like fedora `21` or ubuntu `precise`)
* PACK - packager type [deb or rpm]
* PROD - product name(Debian only)
* P_URI - github uri to clone(Debian only)

Exclusion:
We can exclude some builds from packaging:
https://docs.travis-ci.com/user/customizing-the-build/#Build-Matrix

Build.sh example:
```bash
mkdir -p rpmbuild/SOURCES
git clone -b $1 https://github.com/tarantool/tarantool-c.git
cd tarantool-c
git submodule update --init --recursive
tar cvf `cat tarantool-c.spec | grep Version: |sed -e  's/Version: //'`.tar.gz . --exclude=.git
sudo yum-builddep -y tarantool-c.spec

cp *.tar.gz ../rpmbuild/SOURCES/
rpmbuild -ba tarantool-c.spec
cd ../

# move source rpm
sudo mv /home/rpm/rpmbuild/SRPMS/*.src.rpm result/

# move rpm, devel, debuginfo
sudo mv /home/rpm/rpmbuild/RPMS/x86_64/*.rpm result/
ls -liah result
```

N.B. Now we build packages only for master branch(or for stuff hardcoded in `pack.sh`)
So, you can use pack.sh to get docker container and build packages in `.travis.yml`:
```yaml
script:
  - cd pack
  - sh pack.sh $PACK $OS $DIST $TRAVIS_BRANCH $OUT_REPO $PROD $P_URI
```

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
