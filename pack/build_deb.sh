git config --global user.email "builder@tarantool.org"
git config --global user.name "Builder"

#sudo pip install debuilder
python result/build_py.py $1 $2 $3 $4 $5

ls -liah distros/$2_amd64/builddir

sudo mv -f distros/$2_amd64/builddir/*.deb result/
sudo mv -f distros/$2_amd64/builddir/*.dsc result/
sudo mv -f distros/$2_amd64/builddir/*.gz result/
sudo mv -f distros/$2_amd64/builddir/*.xz result/

ls -liah result
