#!/bin/bash

ROCKSPEC=$1

tarantool_install(){
    sudo yum install -y tarantool-devel
}

libsmall_install(){
    sudo yum install -y small-devel
}

libmsgpuck_install(){
    sudo yum install -y msgpuck-devel
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
