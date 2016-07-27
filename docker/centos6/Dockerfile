FROM centos:6
MAINTAINER Roman Tsisyk <roman@tarantool.org>

# http://people.centos.org/tru/devtools-1.1/readme
RUN curl http://people.centos.org/tru/devtools-1.1/devtools-1.1.repo -o /etc/yum.repos.d/devtools-1.1.repo
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
RUN yum -y install devtoolset-1.1
RUN yum -y install yum-utils rpm-build rpmdevtools
RUN yum -y install sudo wget git
RUN sed -i.bak -n -e '/^Defaults.*requiretty/ { s/^/# /;};/^%wheel.*ALL$/ { s/^/# / ;} ;/^#.*wheel.*NOPASSWD/ { s/^#[ ]*//;};p' /etc/sudoers

RUN echo "source /opt/centos/devtoolset-1.1/enable" > /etc/profile.d/devtoolset-1.1.sh
# Needed for rpmbuild
ENV CC=/opt/centos/devtoolset-1.1/root/usr/bin/gcc
ENV CXX=/opt/centos/devtoolset-1.1/root/usr/bin/g++

ENV LC_ALL="en_US.UTF-8" LANG="en_US.UTF-8"
# Fix paths for mock
ENV PATH /usr/bin:/usr/sbin:/bin:/sbin

# Install dependencies to speed up builds
RUN yum -y install cmake3 readline-devel libyaml-devel binutils-devel \
                   zlib-devel doxygen perl-Test-Harness
RUN yum -y install python-pip python-devel python-daemon python-yaml \
                   python-msgpack python-gevent python-six python-sphinx
# Install gevent-1.0.1
ADD python-gevent-1.0.1-1.x86_64.rpm /tmp/
RUN yum -y install /tmp/python-gevent-1.0.1-1.x86_64.rpm
RUN yum -y install luajit luajit-devel lua lua-devel
ADD tarantool_1_6.repo /etc/yum.repos.d/
RUN yum -q makecache -y --disablerepo='*' --enablerepo='tarantool_1_6'
