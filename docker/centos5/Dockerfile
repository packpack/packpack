FROM centos:5.11
MAINTAINER Roman Tsisyk <roman@tarantool.org>

RUN yum -y install curl ca-certificates
# http://people.centos.org/tru/devtools-2/readme
RUN curl -L http://people.centos.org/tru/devtools-2/devtools-2.repo > /etc/yum.repos.d/devtools-2.repo
RUN curl -O https://dl.fedoraproject.org/pub/epel/epel-release-latest-5.noarch.rpm
RUN curl -O https://download.postgresql.org/pub/repos/yum/9.1/redhat/rhel-5-x86_64/pgdg-redhat91-9.1-7.noarch.rpm
RUN rpm -Uvh epel-release-latest-5.noarch.rpm
RUN rpm -Uvh pgdg-redhat91-9.1-7.noarch.rpm
RUN yum -y install devtoolset-2-toolchain
RUN yum -y install devtoolset-2-binutils-devel
RUN yum -y install yum-utils rpm-build rpmdevtools openssl-devel postgresql91-devel mysql-devel
RUN yum -y install sudo wget git ccache
RUN sed -i.bak -n -e '/^Defaults.*requiretty/ { s/^/# /;};/^%wheel.*ALL$/ { s/^/# / ;} ;/^#.*wheel.*NOPASSWD/ { s/^#[ ]*//;};p' /etc/sudoers

RUN echo "source /opt/rh/devtoolset-2/enable" > /etc/profile.d/devtoolset-2.sh
# Needed for rpmbuild
ENV CC="ccache /opt/rh/devtoolset-2/root/usr/bin/gcc"
ENV CXX="ccache /opt/rh/devtoolset-2//root/usr/bin/g++"

ENV LC_ALL="en_US.UTF-8" LANG="en_US.UTF-8"
# Fix paths for mock
ENV PATH /usr/bin:/usr/sbin:/bin:/sbin

# Install dependencies to speed up builds
RUN yum -y install readline-devel libyaml-devel binutils-devel \
                   zlib-devel doxygen perl-Test-Harness openssl-devel
RUN yum -y install python-pip python-devel python-daemon python-yaml \
                   python-msgpack python-gevent python-six python-sphinx \
                   python-hashlib buildsys-macros cmake28

RUN yum -y install luajit luajit-devel lua lua-devel

COPY features.h /usr/include/features.h
COPY string.h /usr/include/string.h
COPY stat.h /usr/include/sys/stat.h
COPY sysmacros.h /usr/include/sys/sysmacros.h
