mkdir -p rpmbuild/SOURCES

git clone -b $1 $GIT_REPO
cd $PROJECT
git submodule update --init --recursive
tar cvf `cat rpm/${PROJECT}.spec | grep Version: |sed -e  's/Version: //'`.tar.gz . --exclude=.git
sudo yum-builddep -y rpm/$PROJECT.spec

cp *.tar.gz ../rpmbuild/SOURCES/
cp -f rpm/*.ini ../rpmbuild/SOURCES/
rpmbuild -ba rpm/$PROJECT.spec
cd ../

# move source rpm
sudo mv /home/rpm/rpmbuild/SRPMS/*.src.rpm result/

# move rpm, devel, debuginfo
sudo mv /home/rpm/rpmbuild/RPMS/x86_64/*.rpm result/
ls -liah result
