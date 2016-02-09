#!/bin/bash

ROCKSPEC=$1

tarantool_install(){
    curl -s https://packagecloud.io/install/repositories/tarantool/1_6/script.deb.sh | sudo bash
    sudo apt-get install -y tarantool tarantool-dev --force-yes
}

pg_install(){
    sudo apt-get install -y libpq-dev
}

mysql_install(){
    sudo apt-get install -y libmysqlclient-dev
}
libsmall_install(){
    curl -s https://packagecloud.io/install/repositories/tarantool/1_6/script.deb.sh | sudo bash
    sudo apt-get install -y libsmall libsmall-dev
}

libmsgpuck_install(){
    curl -s https://packagecloud.io/install/repositories/tarantool/master/script.deb.sh | sudo bash
    sudo apt-get install -y libmsgpuck-dev
}

if [ `grep TARANTOOL ${ROCKSPEC} | wc -l` != "0" ] ; then
    tarantool_install
fi
if [ `grep POSTGRESQL ${ROCKSPEC} | wc -l` != "0" ] ; then
    pg_install
fi
if [ `grep MYSQL ${ROCKSPEC} | wc -l` != "0" ] ; then
    mysql_install
fi
if [ `grep SMALL ${ROCKSPEC} | wc -l` != "0" ] ; then
    libsmall_install
fi
if [ `grep MSGPUCK ${ROCKSPEC} | wc -l` != "0" ] ; then
    libmsgpuck_install
fi
