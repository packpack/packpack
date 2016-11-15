FROM centos:7
MAINTAINER Roman Tsisyk <roman@tarantool.org>

# Fix missing locales
ENV LC_ALL="C.UTF-8" LANG="C.UTF-8"
# Enable ccache and fix paths for mock
ENV PATH /usr/lib/ccache:/usr/bin:/usr/sbin:/bin:/sbin

RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum -y groupinstall "Development Tools"
RUN yum -y install yum-utils rpm-build rpmdevtools
RUN yum -y install sudo wget git ccache
RUN sed -i.bak -n -e '/^Defaults.*requiretty/ { s/^/# /;};/^%wheel.*ALL$/ { s/^/# / ;} ;/^#.*wheel.*NOPASSWD/ { s/^#[ ]*//;};p' /etc/sudoers

# Install dependencies to speed up builds
RUN yum -y install cmake cmake3 readline-devel libyaml-devel binutils-devel \
                   zlib-devel doxygen perl-Test-Harness openssl-devel
RUN yum -y install python-pip python-devel python-daemon python-yaml \
                   python-msgpack python-gevent python-six python-sphinx \
                   mysql-devel postgresql-devel
RUN pip install requests

RUN yum -y install luajit luajit-devel lua lua-devel
ADD tarantool_1_6.repo /etc/yum.repos.d/
RUN yum -q makecache -y --disablerepo='*' --enablerepo='tarantool_1_6'
