# Alpine Linux is not supported due to problems with libssp and GCC 6.x.
# Use Debian Jessie for gcc-4.x.
#FROM alpine:3.5
FROM debian:jessie-slim
MAINTAINER Roman Tsisyk <roman@tarantool.org>

#RUN apk add --no-cache \
#    gcc \
#    g++ \
#    make \
#    git \
#    libc-dev \
#    zlib-dev

# Fix missing locales
ENV LC_ALL="C.UTF-8" LANG="C.UTF-8"

# Skip interactive post-install scripts
ENV DEBIAN_FRONTEND=noninteractive

# Install base toolset
RUN apt-get update && apt-get install -y --force-yes --no-install-recommends \
    sudo \
    git \
    gcc \
    g++ \
    make \
    cmake \
    tar \
    xz-utils \
    ccache \
    patch \
    diffutils \
    ca-certificates \
    wget \
    libc6-dev \
    zlib1g-dev \
    && \
    apt-get clean

# Enable sudo without password
RUN echo '%adm ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /usr/src

# Compile rumprun toolchain
ADD src-netbsd.patch .
RUN BUILDRUMP_EXTRA="" && \
    git clone https://github.com/rumpkernel/rumprun.git \
        --recursive --depth 1 && \
    cd ./rumprun && \
    cd ./src-netbsd && patch -p1 < ../../src-netbsd.patch && cd .. && \
    ./build-rr.sh -d /usr -o ./obj hw build -- $BUILDRUMP_EXTRA && \
    ./build-rr.sh -d /usr -o ./obj hw install && \
    cd .. && rm -rf ./rumprun

ENV CBUILDROOT=/usr/rumprun-x86_64 \
    CBUILD=x86_64-linux-gnu \
    CHOST=x86_64-rumprun-netbsd

# Add patched CMake toolchain configuration
ADD x86_64-rumprun-netbsd-toolchain.cmake ${CBUILDROOT}/share/
ADD x86_64-rumprun-netbsd-cmake /usr/bin

#
# Install dependencies to speed up builds
#

# Cross-compile LibreSSL
RUN wget http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-2.5.1.tar.gz && \
    tar xvf libressl-*.tar.* && cd libressl-*/ && \
    ./configure \
        --prefix=${CBUILDROOT} \
        --with-sysroot=${CBUILDROOT} \
        --build=${CBUILD} \
        --host=${CHOST} \
        --enable-shared=no && \
    make -j && make install && \
    cd .. && rm -rf libressl-* && \
    rm -rf ${CBUILDROOT}/share/man/ \
           ${CBUILDROOT}/share/info/ \
           ${CBUILDROOT}/share/doc/

# Cross-compile ncurses
RUN wget http://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.0.tar.gz && \
    tar xvf ncurses-*.tar.* && cd ncurses-*/ && \
    ./configure \
        --prefix=${CBUILDROOT} \
        --with-sysroot=${CBUILDROOT} \
        --build=${CBUILD} \
        --host=${CHOST} \
        --includedir=${CBUILDROOT}/include \
        --without-ada \
        --disable-termcap \
        --disable-rpath-hack \
        --without-cxx \
        --without-cxx-binding \
        --without-shared && \
    make -j && make install && \
    cd .. && rm -rf ncurses-* && \
    rm -rf ${CBUILDROOT}/share/man/ \
           ${CBUILDROOT}/share/info/ \
           ${CBUILDROOT}/share/doc/

# Cross-compile libreadline
RUN wget http://ftp.gnu.org/gnu/readline/readline-7.0.tar.gz && \
    tar xvf readline-*.tar.* && cd readline-*/ && \
    SHLIB_XLDFLAGS="" ./configure \
        --prefix=${CBUILDROOT} \
        --with-sysroot=${CBUILDROOT} \
        --build=${CBUILD} \
        --host=${CHOST} \
        --enable-static \
        --disable-shared && \
    make -j && make install && \
    cd .. && rm -rf readline-* && \
    rm -rf ${CBUILDROOT}/share/man/ \
           ${CBUILDROOT}/share/info/ \
           ${CBUILDROOT}/share/doc/

WORKDIR /
