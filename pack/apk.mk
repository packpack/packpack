#
# Packer for Alpine Linux
#

ifeq (,$(wildcard apk/APKBUILD))
$(error Can't find apk/APKBUILD)
endif

APKBUILDIN := $(wildcard apk/APKBUILD)
APKBUILD := APKBUILD

$(BUILDDIR)/$(APKBUILD): $(APKBUILDIN)
	@echo "-------------------------------------------------------------------"
	@echo "Patching APKBUILD"
	@echo "-------------------------------------------------------------------"
	@cp $< $@.tmp
	sed \
		-e 's/pkgver=.*/pkgver="$(VERSION)"/' \
		-e 's/pkgrel=.*/pkgrel="$(RELEASE)"/' \
		-e 's/source=.*/source="$(TARBALL)"/' \
		-i $@.tmp
	grep -F 'pkgver="$(VERSION)"' $@.tmp && \
		grep -F 'pkgrel="$(RELEASE)"' $@.tmp && \
		grep -F 'source="$(TARBALL)"' $@.tmp || \
		(echo "Failed to patch APKBUILD" && exit 1)
	@ mv -f $@.tmp $@
	@echo

#
# Build APK packages
#
package: $(BUILDDIR)/$(TARBALL) \
		 $(BUILDDIR)/$(APKBUILD) \
		 prebuild \
		 prebuild-$(OS) \
		 prebuild-$(OS)-$(DIST)
	@echo
	@echo "-------------------------------------------------------------------"
	@echo "Building APK packages"
	@echo "-------------------------------------------------------------------"
	sudo apk update
	rm -f $(BUILDDIR)/*/APKINDEX.tar.gz
	rm -rf $(BUILDDIR)/src
	cd $(BUILDDIR); abuild checksum
	cd $(BUILDDIR); abuild -r -P $(BUILDDIR) -s $(BUILDDIR)
	mv -f $(BUILDDIR)/*/*.apk $(BUILDDIR)
	@echo "------------------------------------------------------------------"
	@echo "APK packages are ready"
	@echo "-------------------------------------------------------------------"
	@ls -1s $(BUILDDIR)/*.apk
	@echo "--"
	@echo

clean::
	rm -f $(BUILDDIR)/$(APKBUILD)
	rm -f $(BUILDDIR)/*.apk

.PHONY: prebuild prebuild-$(OS) prebuild-$(OS)-$(DIST)
