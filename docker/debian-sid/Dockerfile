FROM debian:sid
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
    ca-certificates
#ADD backports.list /etc/apt/sources.list.d/
#ADD preferences /etc/apt/preferences.d/
#RUN curl -L https://packagecloud.io/packpack/backports/gpgkey | apt-key add -
#ADD packpack_backports.list /etc/apt/sources.list.d/
#RUN curl -L https://packagecloud.io/tarantool/1_6/gpgkey | apt-key add -
#ADD tarantool_1_6.list /etc/apt/sources.list.d/

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
    alien \
    dh-systemd

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
    python-msgpack \
    python-gevent \
    python-six \
    python-sphinx \
    luajit \
    lua5.1 liblua5.1-dev \
    lua5.2 liblua5.2-dev \
    lua5.3 liblua5.3-dev \
    dh-lua
