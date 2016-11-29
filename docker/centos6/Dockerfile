FROM centos:6
MAINTAINER Roman Tsisyk <roman@tarantool.org>

# Fix missing locales
ENV LC_ALL="en_US.UTF-8" LANG="en_US.UTF-8"

# Enable extra repositories
RUN yum -y install epel-release centos-release-scl centos-release-scl-rh
ADD tarantool_1_6.repo /etc/yum.repos.d/
RUN yum -q makecache -y --disablerepo='*' --enablerepo='tarantool_1_6'
RUN yum -y install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-6-x86_64/pgdg-centos96-9.6-3.noarch.rpm

# Install base toolset
RUN yum -y groupinstall 'Development Tools'
RUN yum -y install \
    devtoolset-4-toolchain devtoolset-4-binutils-devel \
    sudo \
    wget \
    curl \
    yum-utils

# Enable sudo without tty
RUN sed -i.bak -n -e '/^Defaults.*requiretty/ { s/^/# /;};/^%wheel.*ALL$/ { s/^/# / ;} ;/^#.*wheel.*NOPASSWD/ { s/^#[ ]*//;};p' /etc/sudoers

# Enable devtoolset and ccache system-wide
# See /opt/rh/devtoolset-4/enable
ENV PATH=/usr/lib64/ccache:/opt/rh/devtoolset-4/root/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LD_LIBRARY_PATH=/opt/rh/devtoolset-4/root/usr/lib64:/opt/rh/devtoolset-4/root/usr/lib
ENV PERL5LIB=/opt/rh/devtoolset-4/root//usr/lib64/perl5/vendor_perl:/opt/rh/devtoolset-4/root/usr/lib/perl5:/opt/rh/devtoolset-4/root//usr/share/perl5/vendor_perl
ENV PYTHONPATH=/opt/rh/devtoolset-4/root/usr/lib64/python2.6/site-packages:/opt/rh/devtoolset-4/root/usr/lib/python2.6/site-packages
ENV XDG_CONFIG_DIRS=/opt/rh/devtoolset-4/root/etc/xdg:/etc/xdg
ENV XDG_DATA_DIRS=/opt/rh/devtoolset-4/root/usr/share:/usr/local/share:/usr/share
# sudo wrapper from devtoolset is buggy, remove it
RUN rm -f /opt/rh/devtoolset-4/root/usr/bin/sudo

# Install dependencies to speed up builds
RUN yum -y install \
    cmake cmake28 cmake3 \
    openssl-devel \
    zlib-devel \
    readline-devel \
    binutils-devel \
    libyaml-devel \
    doxygen \
    postgresql96-devel \
    mysql-devel \
    perl \
    python-pip \
    python-devel \
    python-daemon \
    python-yaml \
    python-msgpack \
    python-gevent \
    python-six \
    python-sphinx

# Install argparse
RUN pip install argparse
# Install gevent-1.0.1
ADD python-gevent-1.0.1-1.x86_64.rpm /tmp/
RUN yum -y install /tmp/python-gevent-1.0.1-1.x86_64.rpm
