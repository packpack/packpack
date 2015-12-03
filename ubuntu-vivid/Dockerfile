from ubuntu:vivid

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
    cdbs \
    equivs \
    lua5.1 \
    rpm \
    alien

RUN pip install debuilder

RUN useradd -s /bin/bash -G adm,sudo -m deb
WORKDIR /home/deb

RUN mkdir /home/deb/result
RUN echo vivid > /home/deb/relname
RUN chown -R deb: /home/deb
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER deb
