FROM debian:sid
MAINTAINER Roman Tsisyk <roman@tarantool.org>

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
