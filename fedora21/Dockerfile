FROM fedora:21

RUN yum -y groupinstall 'Development Tools'
RUN yum -y install fedora-packager
RUN yum -y install yum-utils rpm-build
RUN yum -y install git gcc gcc-c++ kernel-devel make automake lua

RUN yum -y install sudo
RUN sed -i.bak -n -e '/^Defaults.*requiretty/ { s/^/# /;};/^%wheel.*ALL$/ { s/^/# / ;} ;/^#.*wheel.*NOPASSWD/ { s/^#[ ]*//;};p' /etc/sudoers

RUN yum install -y https://rdo.fedorapeople.org/rdo-release.rpm

RUN useradd -s /bin/bash -G adm,wheel,systemd-journal -m rpm
WORKDIR /home/rpm

RUN mkdir /home/rpm/result
RUN chown -R rpm: /home/rpm

USER rpm
