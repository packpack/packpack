#
# Packer for RPM packages
#

RPMSPECIN := $(wildcard rpm/*.spec *.spec)
ifeq ($(RPMSPECIN),)
$(error Can't find RPM spec in rpm/ directory)
endif
$(info Using $(RPMSPECIN) file)

EXTRA_SOURCE_FILES := $(filter-out $(RPMSPECIN),$(wildcard rpm/*))

RPMSPEC_AVAIL := $(shell command -v rpmspec 2> /dev/null)

ifndef RPMSPEC_AVAIL
RPMNAME := $(shell sed -n -e 's/Name:\([\ \t]*\)\(.*\)/\2/p' $(RPMSPECIN))
else
RPMNAME := $(shell rpmspec -P $(RPMSPECIN) | sed -n -e 's/Name:\([\ \t]*\)\(.*\)/\2/p')
endif

RPMDIST := $(shell rpm -E "%{dist}")
PKGVERSION := $(VERSION)-$(RELEASE)$(RPMDIST)
RPMSPEC := $(RPMNAME).spec
RPMSRC := $(RPMNAME)-$(PKGVERSION).src.rpm
PREBUILD := prebuild.sh
PREBUILD_OS := prebuild-$(OS).sh
PREBUILD_OS_DIST := prebuild-$(OS)-$(DIST).sh
THEDATE := $(shell date +"%a %b %d %Y")


#
# Run prebuild scripts
#
ifeq ($(wildcard rpm/$(PREBUILD)),)
prebuild:
	# empty
else
prebuild: rpm/$(PREBUILD)
	@echo "-------------------------------------------------------------------"
	@echo "Running common $(PREBUILD) script"
	@echo "-------------------------------------------------------------------"
	$<
	@echo
endif

ifeq ($(wildcard rpm/$(PREBUILD_OS)),)
prebuild-$(OS): prebuild
	# empty
else
prebuild-$(OS): rpm/$(PREBUILD_OS) prebuild
	@echo "-------------------------------------------------------------------"
	@echo "Running $(PREBUILD_OS) script"
	@echo "-------------------------------------------------------------------"
	$<
	@echo
endif

ifeq ($(wildcard rpm/$(PREBUILD_OS_DIST)),)
prebuild-$(OS)-$(DIST): prebuild-$(OS)
	# empty
else
prebuild-$(OS)-$(DIST): rpm/$(PREBUILD_OS_DIST) prebuild-$(OS)
	@echo "-------------------------------------------------------------------"
	@echo "Running $(PREBUILD_OS_DIST) script"
	@echo "-------------------------------------------------------------------"
	$<
	@echo
endif


$(BUILDDIR)/$(RPMSPEC): $(RPMSPECIN)
	@echo "-------------------------------------------------------------------"
	@echo "Patching RPM spec"
	@echo "-------------------------------------------------------------------"
	@cp $< $@.tmp
	sed \
		-e 's/Version:\([ ]*\).*/Version: $(VERSION)/' \
		-e 's/Release:\([ ]*\).*/Release: $(RELEASE)%{dist}/' \
		-e 's/Source0:\([ ]*\).*/Source0: $(TARBALL)/' \
		-e 's/%setup.*/%setup -q -n $(PRODUCT)-$(VERSION)/' \
                -re 's/(%autosetup.*)( -n \S*)(.*)/\1\3/' \
		-e '0,/%autosetup.*/ s/%autosetup.*/%autosetup -n $(PRODUCT)-$(VERSION)/' \
                -e '/%changelog/a\* $(THEDATE) $(CHANGELOG_NAME) <$(CHANGELOG_EMAIL)> - $(VERSION)-$(RELEASE)\n\- $(CHANGELOG_TEXT)\n' \
		-i $@.tmp
	grep -F "Version: $(VERSION)" $@.tmp && \
		grep -F "Release: $(RELEASE)" $@.tmp && \
		grep -F "Source0: $(TARBALL)" $@.tmp && \
		(grep -F "%setup -q -n $(PRODUCT)-$(VERSION)" $@.tmp || \
		grep -F "%autosetup" $@.tmp) || \
		(echo "Failed to patch RPM spec" && exit 1)
	@ mv -f $@.tmp $@
	@echo

#
# Build source RPM
#
$(BUILDDIR)/$(RPMSRC): $(BUILDDIR)/$(TARBALL) \
                       $(BUILDDIR)/$(RPMSPEC) \
                       prebuild-$(OS)-$(DIST)
	@echo "-------------------------------------------------------------------"
	@echo "Copying extra source files"
	@echo "-------------------------------------------------------------------"
	test -z "$(EXTRA_SOURCE_FILES)" || cp -pR $(EXTRA_SOURCE_FILES) $(BUILDDIR)/
	@echo "-------------------------------------------------------------------"
	@echo "Building source package"
	@echo "-------------------------------------------------------------------"
	rpmbuild \
		--define '_topdir $(BUILDDIR)' \
		--define '_sourcedir $(BUILDDIR)' \
		--define '_specdir $(BUILDDIR)' \
		--define '_srcrpmdir $(BUILDDIR)' \
		--define '_builddir $(BUILDDIR)/usr/src/debug' \
		-bs $(BUILDDIR)/$(RPMSPEC)
prepare: $(BUILDDIR)/$(RPMSRC)

#
# Build RPM packages
#
package: $(BUILDDIR)/$(RPMSRC)
	@echo "-------------------------------------------------------------------"
	@echo "Installing dependencies"
	@echo "-------------------------------------------------------------------"
	if [ -n "$(PACKAGECLOUD_USER)" ] && [ -n "$(PACKAGECLOUD_REPO)" ]; then \
		curl -s https://packagecloud.io/install/repositories/$(PACKAGECLOUD_USER)/$(PACKAGECLOUD_REPO)/script.rpm.sh | sudo bash; \
	fi
	sudo dnf builddep -y $< || sudo yum-builddep -y $<
	@echo
	@echo "-------------------------------------------------------------------"
	@echo "Building RPM packages"
	@echo "-------------------------------------------------------------------"
	rpmbuild \
		--define '_topdir $(BUILDDIR)' \
		--define '_sourcedir $(BUILDDIR)' \
		--define '_specdir $(BUILDDIR)' \
		--define '_srcrpmdir $(BUILDDIR)' \
		--define '_builddir $(BUILDDIR)/usr/src/debug' \
		--define '_smp_mflags $(SMPFLAGS)' \
		--rebuild --with backtrace $< 2>&1 | tee $(BUILDDIR)/build.log
	mv -f $(BUILDDIR)/RPMS/*/*.rpm $(BUILDDIR)
	rm -rf $(BUILDDIR)/RPMS/ $(BUILDDIR)/BUILDROOT $(BUILDDIR)/usr
	@echo "------------------------------------------------------------------"
	@echo "RPM packages are ready"
	@echo "-------------------------------------------------------------------"
	@ls -1s $(BUILDDIR)/*$(RPMNAME)*$(PKGVERSION).*.rpm  $(BUILDDIR)/build.log
	@echo "--"
	@echo

# Upload .src.rpm to koji.fedoraproject.org
koji: $(BUILDDIR)/$(RPMSRC)
	koji build --scratch rawhide $<

clean::
	rm -f $(BUILDDIR)/$(RPMSPEC)
	rm -f $(BUILDDIR)/$(RPMSRC)
	rm -f $(BUILDDIR)/*.rpm
	rm -f $(BUILDDIR)/build.log
	rm -rf $(BUILDDIR)/$(RPMNAME)-$(VERSION)/

.PRECIOUS:: $(BUILDDIR)/$(RPMNAME)-$(VERSION)/ $(BUILDDIR)/$(RPMSRC)
.PHONY: prebuild prebuild-$(OS) prebuild-$(OS)-$(DIST)
