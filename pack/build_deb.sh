git config --global user.email "builder@tarantool.org"
git config --global user.name "Builder"

taranrocks_repo="https://github.com/tarantool/luarocks.git"

luarocks_export(){
    sudo cp *.deb ../result
}

luarocks_deb(){
    echo '[Lua module detected]'
    git clone "${taranrocks_repo}"
    ./luarocks/src/bin/luarocks build --build-deb `ls *.rockspec | head -n 1`
}

tarantool_install(){
    # not working for debian stretch
    # release=`lsb_release -c -s`
    os_id=`lsb_release -i -s | sed 's/.*/\L&/'`
    rel_name=`sudo cat /home/deb/relname`
    echo "deb http://tarantool.org/dist/master/$os_id/ $rel_name main" >> tarantool.list
    echo "deb-src http://tarantool.org/dist/master/$os_id/ $rel_name main" >> tarantool.list
    sudo cp tarantool.list /etc/apt/sources.list.d/
    sudo apt-get update
    sudo apt-get install -y tarantool tarantool-dev --force-yes
}

pg_install(){
    sudo apt-get install -y libpq-dev
}

mysql_install(){
    sudo apt-get install -y libmysqlclient-dev
}

# Install build deps
git clone -b $3 $5
if [ -d $4/debian ] ; then
    cd $4
    sudo mk-build-deps -i --tool "apt-get -y"
    sudo rm -f *.deb
    cd ../

    python result/build_py.py $1 $2 $3 $4 $5
    ls -liah distros/$2_amd64/builddir

    sudo mv -f distros/$2_amd64/builddir/*.deb result/
    sudo mv -f distros/$2_amd64/builddir/*.dsc result/
    sudo mv -f distros/$2_amd64/builddir/*.gz result/
    sudo mv -f distros/$2_amd64/builddir/*.xz result/
elif [ `ls -1 $4/ | grep .rockspec | wc -l` != "0" ] ; then
    cd $4
    if [ `grep TARANTOOL *.rockspec | wc -l` != "0" ] ; then
        tarantool_install
    fi
    if [ `grep POSTGRESQL *.rockspec | wc -l` != "0" ] ; then
        pg_install
    fi
    if [ `grep MYSQL *.rockspec | wc -l` != "0" ] ; then
        mysql_install
    fi
    luarocks_deb
    luarocks_export
    cd ../
else
    echo 'Nothing to build'
fi

ls -liah result
