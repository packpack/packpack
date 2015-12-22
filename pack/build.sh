mkdir -p rpmbuild/SOURCES

if [ -f /usr/bin/scl ] ; then
    # centos 6 devtoolset support
    echo 'SCL MODE'
    export CC=/opt/rh/devtoolset-2/root/usr/bin/gcc
    export CPP=/opt/rh/devtoolset-2/root/usr/bin/cpp
    export CXX=/opt/rh/devtoolset-2/root/usr/bin/c++
fi

branch=$1
git_url=$2
project=$3

taranrocks_repo="https://github.com/tarantool/luarocks.git"

luarocks_export(){
    sudo cp *.rpm ../result
}

luarocks_rpm(){
    echo '[Lua module detected]'
    git clone "${taranrocks_repo}"
    ./luarocks/src/bin/luarocks build --build-rpm `ls *.rockspec | head -n 1`
}

common_export(){
    echo '[Common build]'
    # move source rpm
    sudo mv -f /home/rpm/rpmbuild/SRPMS/*.src.rpm result/

    # move rpm, devel, debuginfo
    sudo mv -f /home/rpm/rpmbuild/RPMS/x86_64/*.rpm result/
    sudo mv -f /home/rpm/rpmbuild/RPMS/noarch/*.rpm result/
}

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

common_rpm(){
    # create tarball
    echo `git describe --long`
    git describe --long > VERSION
    tar cvf `git describe --long | sed "s/-[0-9]*-.*//"`.tar.gz . --exclude=.git

    # install build deps
    sudo yum-builddep -y rpm/$project.spec

    cp *.tar.gz ../rpmbuild/SOURCES/
    cp -f rpm/*.ini ../rpmbuild/SOURCES/
    cp VERSION ../rpmbuild/SOURCES
    rpmbuild -ba rpm/$project.spec
}

git clone -b $branch $git_url
cd $project
git submodule update --init --recursive
if [ -d rpm ] ; then
    common_rpm
    cd ../
    common_export
elif [ `ls -1 | grep *.rockspec | wc -l` != "0" ] ; then
    if [ `grep TARANTOOL *.rockspec | wc -l` != "0" ] ; then
        tarantool_install
    fi
    if [ `grep POSTGRESQL *.rockspec | wc -l` != "0" ] ; then
        pg_install
    fi
    if [ `grep MYSQL *.rockspec | wc -l` != "0" ] ; then
        mysql_install
    fi
    if [ `grep SMALL *.rockspec | wc -l` != "0" ] ; then
        libsmall_install
    fi
    if [ `grep MSGPUCK *.rockspec | wc -l` != "0" ] ; then
        libmsgpuck_install
    fi
    luarocks_rpm
    luarocks_export
    cd ../
else
    echo 'Nothing to build'
fi

ls -liah result
