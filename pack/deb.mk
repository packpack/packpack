#
# Packer for Debian packages
#

DEB_VERSION:=$(VERSION)
ifneq ($(shell dpkg-parsechangelog|grep ^Version|grep -E "g[a-z0-9]{7}\-[0-9]+"),)
# Add git hash to follow convention of official Debian packages
DEB_VERSION := $(VERSION).g$(shell echo $(REVISION)|cut -c1-7)
$(info Added git hash to Debian package version: $(VERSION) => $(DEB_VERSION))
endif

DPKG_ARCH:=$(shell dpkg --print-architecture)
DPKG_CHANGES:=$(PRODUCT)_$(DEB_VERSION)-$(RELEASE)_$(DPKG_ARCH).changes
DPKG_BUILD:=$(PRODUCT)_$(DEB_VERSION)-$(RELEASE)_$(DPKG_ARCH).build
DPKG_DSC:=$(PRODUCT)_$(DEB_VERSION)-$(RELEASE).dsc
DPKG_ORIG_TARBALL:=$(PRODUCT)_$(DEB_VERSION).orig.tar.$(TARBALL_COMPRESSOR)
DPKG_DEBIAN_TARBALL:=$(PRODUCT)_$(DEB_VERSION)-$(RELEASE).debian.tar.$(TARBALL_COMPRESSOR)

# gh-7: Ubuntu/Debian should export DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive

#
# Prepare build directory
#
$(BUILDDIR)/$(PRODUCT)-$(VERSION)/debian/: $(BUILDDIR)/$(TARBALL)
	@echo "-------------------------------------------------------------------"
	@echo "Preparing build directory"
	@echo "-------------------------------------------------------------------"
	cd $(BUILDDIR) && tar xf $<
	test -d $(BUILDDIR)/$(PRODUCT)-$(VERSION)
	cp -pfR debian/ $(BUILDDIR)/$(PRODUCT)-$(VERSION)
	cd $(BUILDDIR)/$(PRODUCT)-$(VERSION) && \
		NAME=$(CHANGELOG_NAME) DEBEMAIL=$(CHANGELOG_EMAIL) \
		dch -b -v "$(DEB_VERSION)-$(RELEASE)" "$(CHANGELOG_TEXT)"

#
# Create a symlink for orig.tar.gz
#
$(BUILDDIR)/$(DPKG_ORIG_TARBALL): $(BUILDDIR)/$(TARBALL)
	cd $(BUILDDIR) && ln -s $(TARBALL) $(DPKG_ORIG_TARBALL)

prepare: $(BUILDDIR)/$(PRODUCT)-$(VERSION)/debian/ \
         $(BUILDDIR)/$(DPKG_ORIG_TARBALL)

#
# Build packages
#
$(BUILDDIR)/$(DPKG_CHANGES): $(BUILDDIR)/$(PRODUCT)-$(VERSION)/debian/ \
                             $(BUILDDIR)/$(DPKG_ORIG_TARBALL)
	@echo "-------------------------------------------------------------------"
	@echo "Installing dependencies"
	@echo "-------------------------------------------------------------------"
	## Clear APT cache to fix Hash sum mismatch
	# sudo apt-get clean
	# sudo rm -rf /var/lib/apt/lists/*
	sudo apt-get update > /dev/null
	cd $(BUILDDIR)/$(PRODUCT)-$(VERSION) && sudo mk-build-deps -i --tool "apt-get --no-install-recommends -y" || :
	cd $(BUILDDIR)/$(PRODUCT)-$(VERSION) && sudo rm -f *build-deps_*.deb
	@echo
	@echo "-------------------------------------------------------------------"
	@echo "Building Debian packages"
	@echo "-------------------------------------------------------------------"
	rm -rf $(BUILDDIR)/tarball
	cd $(BUILDDIR)/$(PRODUCT)-$(VERSION) && \
		debuild --preserve-envvar CCACHE_DIR --prepend-path=/usr/lib/ccache \
		-Z$(TARBALL_COMPRESSOR) -uc -us $(SMPFLAGS)
	rm -rf $(BUILDDIR)/$(PRODUCT)-$(VERSION)/
	@echo "------------------------------------------------------------------"
	@echo "Debian packages are ready"
	@echo "-------------------------------------------------------------------"
	@ls -1s $(BUILDDIR)/$(DPKG_CHANGES) \
		  $(BUILDDIR)/$(DPKG_BUILD) \
		  $(BUILDDIR)/$(DPKG_DEBIAN_TARBALL) \
		  $(BUILDDIR)/$(DPKG_ORIG_TARBALL) \
		  $(BUILDDIR)/$(DPKG_DSC) \
		  $(BUILDDIR)/*.deb
	@echo "--"
	@echo

package: $(BUILDDIR)/$(DPKG_CHANGES)

#
# Remove the build directory
#
clean::
	rm -f $(BUILDDIR)/$(DPKG_CHANGES)
	rm -f $(BUILDDIR)/$(DPKG_BUILD)
	rm -f $(BUILDDIR)/$(DPKG_ORIG_TARBALL)
	rm -f $(BUILDDIR)/$(DPKG_DEBIAN_TARBALL)
	rm -f $(BUILDDIR)/$(DPKG_DSC)
	rm -f $(BUILDDIR)/*.deb
	rm -rf $(BUILDDIR)/$(PRODUCT)-$(VERSION)/

.PHONY: clean
.PRECIOUS:: $(BUILDDIR)/$(PRODUCT)-$(VERSION)/
