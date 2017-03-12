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
DEB_SOURCE_FORMAT:=$(shell cat debian/source/format)
ifneq ("$(DEB_SOURCE_FORMAT)","3.0 (native)")
ifneq ("$(DEB_SOURCE_FORMAT)","3.0 (quilt)")
define ERROR_UNSUPPORTED_FORMAT
Unsupported Debian source package format.
PackPack supports 3.0 (native) and 3.0 (quilt) source formats.
Please refer to https://wiki.debian.org/Projects/DebSrc3.0 and
dpkg-source(1) for additional information
endef
$(error $(ERROR_UNSUPPORTED_FORMAT))
endif
endif

# gh-7: Ubuntu/Debian should export DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive

#
# Prepare the build directory
#
$(BUILDDIR)/$(PRODUCT)-$(VERSION)/debian: $(BUILDDIR)/$(TARBALL)
	@echo "-------------------------------------------------------------------"
	@echo "Preparing build directory"
	@echo "-------------------------------------------------------------------"
	# Unpack the source tarball
	cd $(BUILDDIR) && tar xf $<
	test -d $(BUILDDIR)/$(PRODUCT)-$(VERSION)
	# Add debian/ directory from git
	cp -pfR debian/ $(BUILDDIR)/$(PRODUCT)-$(VERSION)
ifeq ("$(DEB_SOURCE_FORMAT)","3.0 (native)")
	# Convert 3.0 (native) source package to 3.0 (quilt)
	echo "3.0 (quilt)" > $@/source/format
	# Remove debian/patches/ - native package must not have patches/
	rm -rf $@/patches
endif
	# Bump version in debian/changelog
	cd $(BUILDDIR)/$(PRODUCT)-$(VERSION) && \
		NAME="$(CHANGELOG_NAME)" DEBEMAIL=$(CHANGELOG_EMAIL) \
		dch -b -v "$(DEB_VERSION)-$(RELEASE)" "$(CHANGELOG_TEXT)"

$(BUILDDIR)/$(DPKG_ORIG_TARBALL): $(BUILDDIR)/$(TARBALL)
	# Create a symlink for orig.tar.gz
	cd $(BUILDDIR) && ln -s $(TARBALL) $(DPKG_ORIG_TARBALL)

prepare: $(BUILDDIR)/$(PRODUCT)-$(VERSION)/debian \
         $(BUILDDIR)/$(DPKG_ORIG_TARBALL)

#
# Build packages
#
$(BUILDDIR)/$(DPKG_CHANGES): $(BUILDDIR)/$(PRODUCT)-$(VERSION)/debian \
                             $(BUILDDIR)/$(DPKG_ORIG_TARBALL)
	@echo "-------------------------------------------------------------------"
	@echo "Installing dependencies"
	@echo "-------------------------------------------------------------------"
	if [ -n "$(PACKAGECLOUD_USER)" ] && [ -n "$(PACKAGECLOUD_REPO)" ]; then \
		curl -s https://packagecloud.io/install/repositories/$(PACKAGECLOUD_USER)/$(PACKAGECLOUD_REPO)/script.deb.sh | sudo bash; \
	fi
	sudo apt-get update > /dev/null
	cd $(BUILDDIR)/$(PRODUCT)-$(VERSION) && \
		sudo mk-build-deps -i --tool "apt-get --no-install-recommends -y" && \
		sudo rm -f *build-deps_*.deb \
	@echo
	@echo "-------------------------------------------------------------------"
	@echo "Building Debian packages"
	@echo "-------------------------------------------------------------------"
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
