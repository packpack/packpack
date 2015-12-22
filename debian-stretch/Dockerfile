from debian:stretch

RUN apt-get update && apt-get install -y \
    build-essential \
    devscripts \
    git \
    cmake \
    python \
    python-dev \
    python-distribute \
    python-pip \
    sudo \
    fakeroot \
    debhelper \
    equivs \
    lua5.1 \
    rpm \
    alien \
    cdbs --fix-missing

RUN pip install debuilder

RUN useradd -s /bin/bash -G adm,sudo -m deb
WORKDIR /home/deb

RUN mkdir /home/deb/result
RUN echo stretch > /home/deb/relname
RUN chown -R deb: /home/deb
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN echo 'DISTRIB_ID=Debian' > /home/deb/lsb-release
RUN echo 'DISTRIB_RELEASE=9' >> /home/deb/lsb-release
RUN echo 'DISTRIB_CODENAME=stretch' >> /home/deb/lsb-release
RUN echo 'DISTRIB_DESCRIPTION="Debain 9"' >> /home/deb/lsb-release
RUN cp /home/deb/lsb-release /etc/lsb-release

USER deb
