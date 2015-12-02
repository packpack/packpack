mkdir -p rpmbuild/SOURCES

branch=$1
git_url=$2
project=$3

taranrocks_repo="https://github.com/bigbes/taranrocks.git"

luarocks_export(){
    sudo cp *.rpm ../result
}

luarocks_rpm(){
    echo '[Lua module detected]'
    git clone "${taranrocks_repo}"
    ./taranrocks/src/bin/luarocks build --build-rpm `ls *.rockspec | head -n 1`
}

common_export(){
    echo '[Common build]'
    # move source rpm
    sudo mv -f /home/rpm/rpmbuild/SRPMS/*.src.rpm result/

    # move rpm, devel, debuginfo
    sudo mv -f /home/rpm/rpmbuild/RPMS/x86_64/*.rpm result/
    sudo mv -f /home/rpm/rpmbuild/RPMS/noarch/*.rpm result/
}

common_rpm(){
    # create tarball
    tar cvf `cat rpm/${project}.spec | grep Version: |sed -e  's/Version: //'`.tar.gz . --exclude=.git

    # install build deps
    sudo yum-builddep -y rpm/$project.spec

    cp *.tar.gz ../rpmbuild/SOURCES/
    cp -f rpm/*.ini ../rpmbuild/SOURCES/
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
    luarocks_rpm
    luarocks_export
    cd ../
else
    echo 'Nothing to build'
fi

ls -liah result
