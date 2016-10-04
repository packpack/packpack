ifndef PRODUCT
$(error Missing PRODUCT variable)
endif
ifndef NAME
$(error Missing NAME variable)
endif
ifndef TARBALL
$(error Missing TARBALL variable)
endif
ifndef VERSION
$(error Missing VERSION variable)
endif
ifndef RELEASE
$(error Missing RELEASE variable)
endif
ifndef DEBEMAIL
DEBEMAIL="build@tarantool.org"
endif
ifndef DEBFULLNAME
DEBFULLNAME="PackPack Cloud Infrastructure"
endif

# https://wiki.debian.org/IntroDebianPackaging:
# The name consists of the source package name, an underscore, the upstream
# version number, followed by .orig.tar.gz
# Note that there is an underscore (_), not a dash (-), in the name.
# This is important, because the packaging tools are picky.
DEB_NAME=$(PRODUCT)_$(VERSION)
DEB_TARBALL=$(DEB_NAME).orig.tar.gz

all: results

# Unpack source tarball
$(NAME)/debian/changelog: $(TARBALL)
	tar xf $<
	mv -f debian/ $(NAME)/
	ls -l $(NAME)/

# Copy tarball to .orig.tar.gz (needed to generate .dsc)
$(DEB_TARBALL): $(TARBALL)
	cp -pf $< $@

# Build packages
$(DEB_NAME)-$(RELEASE).dsc: $(NAME)/debian/changelog $(DEB_TARBALL)
	@echo "-------------------------------------------------------------------"
	@echo "Updating changelog"
	@echo "-------------------------------------------------------------------"
	cd $(NAME) && NAME=$(DEBFULLNAME) DEBEMAIL=$(DEBEMAIL) \
		dch -b -v $(VERSION)-$(RELEASE) "Automatic build"
	@echo "-------------------------------------------------------------------"
	@echo "Installing dependencies"
	@echo "-------------------------------------------------------------------"
	# Clear APT cache to fix Hash sum mismatch
	sudo apt-get clean
	sudo rm -rf /var/lib/apt/lists/*
	sudo apt-get update > /dev/null
	cd $(NAME) && sudo mk-build-deps -i --tool "apt-get -y" || :
	cd $(NAME) && sudo rm -f *build-deps_*.deb
	@echo
	@echo "-------------------------------------------------------------------"
	@echo "Building packages"
	@echo "-------------------------------------------------------------------"
	cd $(NAME) && debuild -uc -us -j4

results: $(DEB_NAME)-$(RELEASE).dsc
	@echo "-------------------------------------------------------------------"
	@echo "Copying packages"
	@echo "-------------------------------------------------------------------"
	mkdir -p $@.tmp/
	mv -f *.deb *.changes *.dsc $@.tmp/
	mv -f *.debian.tar.* *.orig.tar.* $@.tmp/
	mv -f *.build $@.tmp/build.log
	mv -f $@.tmp $@
	touch $@/.done
