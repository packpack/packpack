#
# Packer for Debian packages
#

# Tarantool: don't use long paths to avoid "AF_UNIX path too long"
RPMDIST=$(shell rpm -E "%{dist}")
PKGVERSION=$(VERSION)-$(RELEASE)$(RPMDIST)
RPMSPEC=$(PRODUCT).spec
RPMSRC=$(PRODUCT)-$(PKGVERSION).src.rpm

$(BUILDDIR)/$(RPMSPEC): rpm/$(RPMSPEC)
	@echo "-------------------------------------------------------------------"
	@echo "Preparing RPM spec"
	@echo "-------------------------------------------------------------------"
	@cp $< $@.tmp
	sed -e 's/Version:\([ ]*\).*/Version: $(VERSION)/' \
		 -e 's/Release:\([ ]*\).*/Release: $(RELEASE)%{dist}/' \
		 -e 's/Source0:\([ ]*\).*/Source0: $(TARBALL)/' \
		 -e 's/%setup .*/%setup -q -n $(PRODUCT)-$(VERSION)/' \
		 -i $@.tmp
	@grep -E "Version:|Release:|Source0|%setup" $@.tmp
	@mv -f $@.tmp $@
	@echo

#
# Build source RPM
#
$(BUILDDIR)/$(RPMSRC): $(BUILDDIR)/$(RPMSPEC) $(BUILDDIR)/$(TARBALL)
	@echo "-------------------------------------------------------------------"
	@echo "Building source package"
	@echo "-------------------------------------------------------------------"
	rpmbuild \
		--define '_topdir $(BUILDDIR)' \
		--define '_sourcedir $(BUILDDIR)' \
		--define '_specdir $(BUILDDIR)' \
		--define '_srcrpmdir $(BUILDDIR)' \
		-bs $(BUILDDIR)/$(RPMSPEC)
prepare: $(BUILDDIR)/$(RPMSRC)

#
# Build RPM packages
#
package: $(BUILDDIR)/$(RPMSRC)
	@echo "-------------------------------------------------------------------"
	@echo "Installing dependencies"
	@echo "-------------------------------------------------------------------"
	sudo yum clean all
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
		--define '_builddir $(BUILDDIR)' \
		--define '_smp_mflags $(SMPFLAGS)' \
		--rebuild --with backtrace $< 2>&1 | tee $(BUILDDIR)/build.log
	mv -f $(BUILDDIR)/RPMS/*/*.rpm $(BUILDDIR)
	rm -rf $(BUILDDIR)/RPMS/ $(BUILDDIR)/BUILDROOT
	@echo "------------------------------------------------------------------"
	@echo "RPM packages are ready"
	@echo "-------------------------------------------------------------------"
	@ls -1s $(BUILDDIR)/*$(PRODUCT)*$(PKGVERSION).*.rpm  $(BUILDDIR)/build.log
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
	rm -rf $(BUILDDIR)/$(PRODUCT)-$(VERSION)/

.PRECIOUS:: $(BUILDDIR)/$(PRODUCT)-$(VERSION)/ $(BUILDDIR)/$(RPMSRC) $(BUILDDIR)/$(RPMSPEC)
