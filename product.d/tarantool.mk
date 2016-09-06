# Add commit number to the version string
VERSION:=$(shell cat VERSION | sed -n 's/^\([0-9\.]*\)-\([0-9]*\)-\([a-z0-9]*\)/\1.\2/p')
RELEASE:=1
# Add git hash in Debian to follow convention used by official packages
DEB_VERSION:=$(shell cat VERSION | sed -n 's/^\([0-9\.]*\)-\([0-9]*\)-\([a-z0-9]*\)/\1.\2.\3/p')

TARBALL_EXTRA_ARGS:= --exclude=doc/www --exclude=doc/sphinx
