FROM debian:stretch
MAINTAINER Roman Tsisyk <roman@tarantool.org>

# Bug#813000: apt complains about corrupted index files even after multiple updates
RUN echo 'APT::Compressor::lz4::Cost "5000";' > /etc/apt/apt.conf.d/disable-lz4
RUN apt-get update && apt-get install -y --force-yes \
    build-essential gdb git \
    devscripts debhelper fakeroot cdbs equivs rpm alien \
    sudo

RUN echo '%adm ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
ENV LC_ALL="C.UTF-8" LANG="C.UTF-8"

# Install dependencies to speed up builds
RUN apt-get update && apt-get install -y \
    cmake libreadline-dev libyaml-dev binutils-dev zlib1g-dev doxygen
RUN apt-get update && apt-get install -y \
    python-pip python-dev python-daemon python-yaml \
    python-gevent python-six python-msgpack python-sphinx
RUN apt-get update && apt-get install -y luajit \
    lua5.1 liblua5.1-dev lua5.2 liblua5.2-dev lua5.3 liblua5.3-dev dh-lua
RUN curl -L https://packagecloud.io/tarantool/1_6/gpgkey | sudo apt-key add -
RUN apt-get update && apt-get install -y apt-transport-https
ADD tarantool_1_6.list /etc/apt/sources.list.d/
RUN apt-get update
