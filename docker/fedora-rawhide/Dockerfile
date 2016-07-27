FROM fedora:rawhide
MAINTAINER Roman Tsisyk <roman@tarantool.org>

RUN dnf -y group install 'Development Tools'
RUN dnf -y group install 'C Development Tools and Libraries'
RUN dnf -y group install 'RPM Development Tools'
RUN dnf -y install fedora-packager fedora-review
RUN dnf -y install sudo wget git
RUN sed -i.bak -n -e '/^Defaults.*requiretty/ { s/^/# /;};/^%wheel.*ALL$/ { s/^/# / ;} ;/^#.*wheel.*NOPASSWD/ { s/^#[ ]*//;};p' /etc/sudoers

ENV LC_ALL="en_US.UTF-8" LANG="en_US.UTF-8"
# Fix paths for mock
ENV PATH /usr/bin:/usr/sbin:/bin:/sbin

# Install dependencies to speed up builds
RUN dnf -y install cmake readline-devel libyaml-devel binutils-devel \
                   zlib-devel doxygen perl-podlators perl-Test-Harness systemd
RUN dnf -y install python-pip python-devel python-daemon python-yaml \
                   python-msgpack python-gevent python-six python-sphinx
RUN dnf -y install luajit luajit-devel lua lua-devel
