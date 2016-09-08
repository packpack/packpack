FROM centos:6
MAINTAINER Roman Tsisyk <roman@tarantool.org>

# http://people.centos.org/tru/devtools-1.1/readme
RUN curl -L http://people.centos.org/tru/devtools-2/devtools-2.repo > /etc/yum.repos.d/devtools-2.repo
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
RUN curl -O https://download.postgresql.org/pub/repos/yum/9.1/redhat/rhel-6-x86_64/pgdg-redhat91-9.1-7.noarch.rpm
RUN rpm -Uvh pgdg-redhat91-9.1-7.noarch.rpm
RUN yum -y install devtoolset-2-toolchain
RUN yum -y install devtoolset-2-binutils-devel
RUN yum -y install yum-utils rpm-build rpmdevtools openssl-devel postgresql91-devel mysql-devel
RUN yum -y install sudo wget git ccache
RUN sed -i.bak -n -e '/^Defaults.*requiretty/ { s/^/# /;};/^%wheel.*ALL$/ { s/^/# / ;} ;/^#.*wheel.*NOPASSWD/ { s/^#[ ]*//;};p' /etc/sudoers

RUN echo "source /opt/rh/devtoolset-2/enable" > /etc/profile.d/devtoolset-2.sh
# Needed for rpmbuild
ENV CC=/opt/rh/devtoolset-2/root/usr/bin/gcc
ENV CXX=/opt/rh/devtoolset-2//root/usr/bin/g++

ENV LC_ALL="en_US.UTF-8" LANG="en_US.UTF-8"
# Fix paths for mock
ENV PATH /usr/lib/ccache:/usr/bin:/usr/sbin:/bin:/sbin

# Install dependencies to speed up builds
RUN yum -y install cmake cmake28 cmake3 readline-devel libyaml-devel binutils-devel \
                   zlib-devel doxygen perl-Test-Harness openssl-devel
RUN yum -y install python-pip python-devel python-daemon python-yaml \
                   python-msgpack python-gevent python-six python-sphinx
RUN pip install argparse

# Install gevent-1.0.1
ADD python-gevent-1.0.1-1.x86_64.rpm /tmp/
RUN yum -y install /tmp/python-gevent-1.0.1-1.x86_64.rpm
RUN yum -y install luajit luajit-devel lua lua-devel
ADD tarantool_1_6.repo /etc/yum.repos.d/
RUN yum -q makecache -y --disablerepo='*' --enablerepo='tarantool_1_6'
