FROM debian:jessie
MAINTAINER Roman Tsisyk <roman@tarantool.org>

ADD backports.list /etc/apt/sources.list.d/
ADD preferences /etc/apt/preferences
RUN apt-get update && apt-get install -y --force-yes \
    build-essential gdb git vim \
    devscripts debhelper fakeroot cdbs equivs rpm alien \
    sudo mc

RUN echo '%adm ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
ENV LC_ALL="C.UTF-8" LANG="C.UTF-8"

# Install dependencies to speed up builds
RUN apt-get update && apt-get install -y \
    cmake libreadline-dev libyaml-dev binutils-dev zlib1g-dev doxygen
RUN apt-get update && apt-get install -y \
    python-pip python-dev python-daemon python-yaml \
    python-gevent python-six python-sphinx
RUN apt-get update && apt-get install -y -t jessie-backports \
    python-msgpack
RUN apt-get update && apt-get install -y luajit \
    lua5.1 liblua5.1-dev lua5.2 liblua5.2-dev dh-lua
RUN apt-get update && apt-get install -y --force-yes \
    build-essential gdb cmake \
    devscripts debhelper fakeroot cdbs equivs rpm alien \
    python sudo vim wget mc git
