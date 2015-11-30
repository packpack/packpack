mkdir -p rpmbuild/SOURCES

branch=$1
git_url=$2
project=$3

git clone -b $branch $git_url
cd $project
git submodule update --init --recursive
tar cvf `cat rpm/${project}.spec | grep Version: |sed -e  's/Version: //'`.tar.gz . --exclude=.git
sudo yum-builddep -y rpm/$project.spec

cp *.tar.gz ../rpmbuild/SOURCES/
cp -f rpm/*.ini ../rpmbuild/SOURCES/
rpmbuild -ba rpm/$project.spec
cd ../

# move source rpm
sudo mv -f /home/rpm/rpmbuild/SRPMS/*.src.rpm result/

# move rpm, devel, debuginfo
sudo mv -f /home/rpm/rpmbuild/RPMS/x86_64/*.rpm result/
sudo mv -f /home/rpm/rpmbuild/RPMS/noarch/*.rpm result/
ls -liah result
