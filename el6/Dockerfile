FROM centos:6

RUN yum -y groupinstall 'Development Tools'
RUN yum -y install yum-utils rpm-build
RUN yum -y install git gcc gcc-c++ kernel-devel make automake tar python-setuptools lua

RUN yum -y install sudo
RUN sed -i.bak -n -e '/^Defaults.*requiretty/ { s/^/# /;};/^%wheel.*ALL$/ { s/^/# / ;} ;/^#.*wheel.*NOPASSWD/ { s/^#[ ]*//;};p' /etc/sudoers

RUN yum install -y https://rdo.fedorapeople.org/rdo-release.rpm
RUN yum install -y wget
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
RUN wget http://people.centos.org/tru/devtools-2/devtools-2.repo -O /etc/yum.repos.d/devtools-2.repo
RUN yum -y install devtoolset-2-toolchain devtoolset-2-binutils-devel

RUN useradd -s /bin/bash -G adm,wheel -m rpm
WORKDIR /home/rpm

RUN mkdir /home/rpm/result
RUN chown -R rpm: /home/rpm
RUN echo centos > /etc/yum/vars/osname

USER rpm
