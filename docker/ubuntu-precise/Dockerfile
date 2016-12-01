FROM ubuntu:precise
MAINTAINER Roman Tsisyk <roman@tarantool.org>

# Fix missing locales
ENV LC_ALL="C.UTF-8" LANG="C.UTF-8"

# Skip interactive post-install scripts
ENV DEBIAN_FRONTEND=noninteractive

# Don't install recommends
RUN echo 'apt::install-recommends "false";' > /etc/apt/apt.conf.d/00recommends

# Enable extra repositories
RUN apt-get update && apt-get install -y --force-yes \
    apt-transport-https \
    curl \
    wget \
    gnupg \
    ca-certificates \
    software-properties-common python-software-properties
ADD backports.list /etc/apt/sources.list.d/
ADD preferences /etc/apt/preferences.d/
RUN curl -s https://packagecloud.io/install/repositories/computology/apt-backport/script.deb.sh | bash
RUN apt-get install -y --force-yes apt=1.2.10
RUN apt-add-repository -y ppa:george-edison55/precise-backports
RUN curl -s https://packagecloud.io/install/repositories/packpack/backports/script.deb.sh | bash
RUN curl -s https://packagecloud.io/install/repositories/tarantool/1_6/script.deb.sh | bash

# Install base toolset
RUN apt-get update && apt-get install -y --force-yes \
    sudo \
    git \
    build-essential \
    gdb \
    ccache \
    devscripts \
    debhelper \
    cdbs \
    fakeroot \
    lintian \
    equivs \
    rpm \
    alien

# Enable sudo without password
RUN echo '%adm ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install dependencies to speed up builds
RUN apt-get update && apt-get install -y --force-yes \
    cmake \
    libssl-dev \
    zlib1g-dev \
    libreadline-dev \
    binutils-dev \
    libyaml-dev \
    doxygen \
    python-pip \
    python-dev \
    python-daemon \
    python-yaml \
    python-gevent \
    python-six \
    python-sphinx \
    luajit \
    lua5.1 liblua5.1-dev \
    lua5.2 liblua5.2-dev \
    dh-lua
RUN pip install msgpack-python
