FROM centos:5.11
MAINTAINER Roman Tsisyk <roman@tarantool.org>

RUN yum -y install curl ca-certificates
# http://people.centos.org/tru/devtools-1.1/readme
RUN curl -L http://people.centos.org/tru/devtools-1.1/devtools-1.1.repo -o /etc/yum.repos.d/devtools-1.1.repo
RUN curl -O https://dl.fedoraproject.org/pub/epel/epel-release-latest-5.noarch.rpm
RUN rpm -Uvh epel-release-latest-5.noarch.rpm
RUN yum -y install devtoolset-1.1
RUN yum -y install yum-utils rpm-build rpmdevtools openssl-devel
RUN yum -y install sudo vim wget mc git
RUN sed -i.bak -n -e '/^Defaults.*requiretty/ { s/^/# /;};/^%wheel.*ALL$/ { s/^/# / ;} ;/^#.*wheel.*NOPASSWD/ { s/^#[ ]*//;};p' /etc/sudoers

RUN echo "source /opt/centos/devtoolset-1.1/enable" > /etc/profile.d/devtoolset-1.1.sh
# Needed for rpmbuild
ENV CC=/opt/centos/devtoolset-1.1/root/usr/bin/gcc
ENV CXX=/opt/centos/devtoolset-1.1/root/usr/bin/g++

ENV LC_ALL="en_US.UTF-8" LANG="en_US.UTF-8"
# Fix paths for mock
ENV PATH /usr/bin:/usr/sbin:/bin:/sbin

# Install dependencies to speed up builds
RUN yum -y install readline-devel libyaml-devel binutils-devel \
                   zlib-devel doxygen perl-Test-Harness
RUN yum -y install python-pip python-devel python-daemon python-yaml \
                   python-msgpack python-gevent python-six python-sphinx

RUN set -e \
    && curl -L -O -k https://www.cmake.org/files/v2.8/cmake-2.8.10.2.tar.gz \
    && tar -zxvf cmake-2.8.10.2.tar.gz \
    && cd cmake-2.8.10.2 \
    && ./bootstrap --prefix=/usr \
    && make \
    && make install

RUN yum -y install luajit luajit-devel lua lua-devel

COPY stat.h /usr/include/sys/stat.h
COPY sysmacros.h /usr/include/sys/sysmacros.h
