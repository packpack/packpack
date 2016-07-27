FROM centos:7
# A container used to build CentOS packages and develop Tarantool
MAINTAINER Roman Tsisyk <roman@tarantool.org>

RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum -y groupinstall "Development Tools"
RUN yum -y install yum-utils rpm-build rpmdevtools
RUN yum -y install sudo wget git
RUN sed -i.bak -n -e '/^Defaults.*requiretty/ { s/^/# /;};/^%wheel.*ALL$/ { s/^/# / ;} ;/^#.*wheel.*NOPASSWD/ { s/^#[ ]*//;};p' /etc/sudoers

ENV LC_ALL="en_US.UTF-8" LANG="en_US.UTF-8"
# Fix paths for mock
ENV PATH /usr/bin:/usr/sbin:/bin:/sbin

# Install dependencies to speed up builds
RUN yum -y install cmake3 readline-devel libyaml-devel binutils-devel \
                   zlib-devel doxygen perl-Test-Harness
RUN yum -y install python-pip python-devel python-daemon python-yaml \
                   python-msgpack python-gevent python-six python-sphinx
RUN yum -y install luajit luajit-devel lua lua-devel
ADD tarantool_1_6.repo /etc/yum.repos.d/
RUN yum -q makecache -y --disablerepo='*' --enablerepo='tarantool_1_6'
