#!/bin/bash

ROCKSPEC=$1

tarantool_install(){
    sudo apt-get install -y tarantool-dev
}

libsmall_install(){
    sudo apt-get install -y libsmall-dev
}

libmsgpuck_install(){
    sudo apt-get install -y libmsgpuck-dev
}

if [ `grep TARANTOOL ${ROCKSPEC} | wc -l` != "0" ] ; then
    tarantool_install
fi
if [ `grep SMALL ${ROCKSPEC} | wc -l` != "0" ] ; then
    libsmall_install
fi
if [ `grep MSGPUCK ${ROCKSPEC} | wc -l` != "0" ] ; then
    libmsgpuck_install
fi
