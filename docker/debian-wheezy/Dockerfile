FROM debian:wheezy
MAINTAINER Roman Tsisyk <roman@tarantool.org>

# Fix missing locales
ENV LC_ALL="C.UTF-8" LANG="C.UTF-8"

# Skip interactive post-install scripts
ENV DEBIAN_FRONTEND=noninteractive

# Don't install recommends
RUN echo 'apt::install-recommends "false";' > /etc/apt/apt.conf.d/00recommends

# Enable extra repositories
RUN apt-get update && apt-get install -y apt-transport-https curl ca-certificates
ADD backports.list /etc/apt/sources.list.d/
ADD preferences /etc/apt/preferences.d/
RUN curl -L https://packagecloud.io/packpack/backports/gpgkey | apt-key add -
ADD packpack_backports.list /etc/apt/sources.list.d/
RUN curl -L https://packagecloud.io/tarantool/1_6/gpgkey | apt-key add -
ADD tarantool_1_6.list /etc/apt/sources.list.d/

RUN apt-get update && apt-get install -y --force-yes \
    build-essential gdb git ccache \
    devscripts debhelper fakeroot cdbs equivs rpm alien \
    sudo dh-systemd

RUN echo '%adm ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install dependencies to speed up builds
RUN apt-get update && apt-get install -y \
    cmake libreadline-dev libyaml-dev binutils-dev zlib1g-dev libssl-dev \
    doxygen
RUN apt-get update && apt-get install -y \
    python-pip python-dev python-daemon python-yaml \
    python-gevent python-six python-sphinx
RUN pip install msgpack-python
RUN apt-get update && apt-get install -y luajit \
    lua5.1 liblua5.1-dev lua5.2 liblua5.2-dev dh-lua
