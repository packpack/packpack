#
# Packer for Debian packages
#

DEB_VERSION:=$(VERSION)
ifneq ($(shell dpkg-parsechangelog|grep ^Version|grep -E "g[abcdef0-9]{7,16}\-[0-9]+"),)
ifneq ($(ABBREV),)
# Add git abbreviation to follow the convention of official Debian packages
DEB_VERSION := $(VERSION).$(ABBREV)
$(info Added git hash to Debian package version: $(VERSION) => $(DEB_VERSION))
endif
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

PREBUILD := prebuild.sh
PREBUILD_OS := prebuild-$(OS).sh
PREBUILD_OS_DIST := prebuild-$(OS)-$(DIST).sh

# gh-7: Ubuntu/Debian should export DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive

#
# Run prebuild scripts
#
ifeq ($(wildcard debian/$(PREBUILD)),)
prebuild:
	# empty
else
prebuild: debian/$(PREBUILD)
	@echo "-------------------------------------------------------------------"
	@echo "Running common $(PREBUILD) script"
	@echo "-------------------------------------------------------------------"
	$<
	@echo
endif

ifeq ($(wildcard debian/$(PREBUILD_OS)),)
prebuild-$(OS): prebuild
	# empty
else
prebuild-$(OS): debian/$(PREBUILD_OS) prebuild
	@echo "-------------------------------------------------------------------"
	@echo "Running $(PREBUILD_OS) script"
	@echo "-------------------------------------------------------------------"
	$<
	@echo
endif

ifeq ($(wildcard debian/$(PREBUILD_OS_DIST)),)
prebuild-$(OS)-$(DIST): prebuild-$(OS)
	# empty
else
prebuild-$(OS)-$(DIST): debian/$(PREBUILD_OS_DIST) prebuild-$(OS)
	@echo "-------------------------------------------------------------------"
	@echo "Running $(PREBUILD_OS_DIST) script"
	@echo "-------------------------------------------------------------------"
	$<
	@echo
endif

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
                             $(BUILDDIR)/$(DPKG_ORIG_TARBALL) \
                             prebuild-$(OS)-$(DIST)
	@echo "-------------------------------------------------------------------"
	@echo "Installing dependencies"
	@echo "-------------------------------------------------------------------"
	if [ -n "$(PACKAGECLOUD_USER)" ] && [ -n "$(PACKAGECLOUD_REPO)" ]; then \
		curl -s https://packagecloud.io/install/repositories/$(PACKAGECLOUD_USER)/$(PACKAGECLOUD_REPO)/script.deb.sh | sudo bash; \
	fi
	sudo rm -rf /var/lib/apt/lists/
	sudo apt-get update > /dev/null
	cd $(BUILDDIR)/$(PRODUCT)-$(VERSION) && \
		sudo mk-build-deps -i --tool "apt-get --no-install-recommends -y" && \
		sudo rm -f *build-deps_*.deb *build-deps_*.buildinfo *build-deps_*.changes \
	@echo
	@echo "-------------------------------------------------------------------"
	@echo "Building Debian packages"
	@echo "-------------------------------------------------------------------"
	cd $(BUILDDIR)/$(PRODUCT)-$(VERSION) && \
		debuild --preserve-envvar CCACHE_DIR --prepend-path=/usr/lib/ccache \
		--preserve-envvar CI \
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

.PHONY: clean prebuild prebuild-$(OS) prebuild-$(OS)-$(DIST)
.PRECIOUS:: $(BUILDDIR)/$(PRODUCT)-$(VERSION)/
