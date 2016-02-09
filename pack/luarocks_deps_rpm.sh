#!/bin/bash

ROCKSPEC=$1

tarantool_install(){
    curl -s https://packagecloud.io/install/repositories/tarantool/1_6/script.rpm.sh | sudo bash
    sudo yum install -y tarantool tarantool-dev
}

pg_install(){
    sudo yum install -y postgresql-devel
    # replace search path for centos/fedora include dirs
    sed -i -e s/postgresql.libpq-fe.h/libpq-fe.h/g *.rockspec
}

mysql_install(){
    sudo yum install -y mysql-devel
    sudo ln -s /usr/lib64/mysql/libmysqlclient_r.so /usr/lib/libmysqlclient_r.so
}

libsmall_install(){
    curl -s https://packagecloud.io/install/repositories/tarantool/1_6/script.rpm.sh | sudo bash
    sudo yum install -y small small-devel
}

libmsgpuck_install(){
    curl -s https://packagecloud.io/install/repositories/tarantool/master/script.rpm.sh | sudo bash
    sudo yum install -y msgpuck-devel
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
