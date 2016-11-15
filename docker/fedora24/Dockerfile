FROM fedora:24
MAINTAINER Roman Tsisyk <roman@tarantool.org>

# Fix missing locales
ENV LC_ALL="C.UTF-8" LANG="C.UTF-8"
# Enable ccache and fix paths for mock
ENV PATH /usr/lib/ccache:/usr/bin:/usr/sbin:/bin:/sbin

RUN dnf -y group install 'Development Tools'
RUN dnf -y group install 'C Development Tools and Libraries'
RUN dnf -y group install 'RPM Development Tools'
RUN dnf -y install fedora-packager
RUN dnf -y install sudo wget git ccache
RUN sed -i.bak -n -e '/^Defaults.*requiretty/ { s/^/# /;};/^%wheel.*ALL$/ { s/^/# / ;} ;/^#.*wheel.*NOPASSWD/ { s/^#[ ]*//;};p' /etc/sudoers

# Install dependencies to speed up builds
RUN dnf -y install cmake readline-devel libyaml-devel binutils-devel \
                   zlib-devel doxygen perl-podlators perl-Test-Harness \
                   openssl-devel systemd
RUN dnf -y install python-pip python-devel python-daemon python-yaml \
                   python-msgpack python-gevent python-six python-sphinx
RUN dnf -y install luajit luajit-devel lua lua-devel
ADD tarantool_1_6.repo /etc/yum.repos.d/
RUN dnf -q makecache -y --disablerepo='*' --enablerepo='tarantool_1_6'
