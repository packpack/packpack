git config --global user.email "builder@tarantool.org"
git config --global user.name "Builder"

taranrocks_repo="https://github.com/bigbes/taranrocks.git"

luarocks_export(){
    sudo cp *.deb ../result
}

luarocks_deb(){
    echo '[Lua module detected]'
    sudo apt-get install  -y lua5.1 rpm alien
    git clone "${taranrocks_repo}"
    ./taranrocks/src/bin/luarocks build --build-deb `ls *.rockspec | head -n 1`
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
    luarocks_deb
    luarocks_export
    cd ../
else
    echo 'Nothing to build'
fi

ls -liah result
