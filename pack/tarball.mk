#
# Packer for source tarballs
#

##
TARBALL ?= $(PRODUCT)-$(VERSION).tar.$(TARBALL_COMPRESSOR)

#
# Generate VERSION file
#
$(BUILDDIR)/VERSION:
	@echo "-------------------------------------------------------------------"
	@echo "Creating VERSION file"
	@echo "-------------------------------------------------------------------"
	@mkdir -p $(BUILDDIR)
	git describe --long --always > $@

#
# Generate the list of source files for tarball
#
$(BUILDDIR)/ls-lR.txt:
	@echo "-------------------------------------------------------------------"
	@echo "Generating the list of source files"
	@echo "-------------------------------------------------------------------"
	@mkdir -p $(BUILDDIR)
	git ls-files > $@
	git submodule --quiet foreach 'git ls-files | sed "s|^|$$path/|"' >> $@

#
# Pack source tarball
#
$(BUILDDIR)/$(TARBALL): $(BUILDDIR)/ls-lR.txt $(BUILDDIR)/VERSION
	@echo "-------------------------------------------------------------------"
	@echo "Creating source tarball"
	@echo "-------------------------------------------------------------------"
	tar \
		--exclude=.git --exclude='.gitignore' --exclude='.gitmodules' \
		$(TARBALL_EXTRA_ARGS) \
		--exclude=FreeBSD --exclude=debian --exclude=rpm --exclude=rump \
		--transform="s,$(BUILDDIR)/VERSION,VERSION,S" \
		--transform="s,,$(PRODUCT)-$(VERSION)/,S" \
		--owner=root --group=root \
		-T $< --show-transformed \
		-caPf $@ $(BUILDDIR)/VERSION $(TARBALL_EXTRA_FILES)
	@echo "------------------------------------------------------------------"
	@echo "Tarball is ready"
	@echo "-------------------------------------------------------------------"
	@ls -1s $(BUILDDIR)/$(TARBALL)
	@echo "--"
	@echo

tarball: $(BUILDDIR)/$(TARBALL)

clean::
	rm -f $(BUILDDIR)/$(TARBALL)

.PRECIOUS:: $(BUILDDIR)/$(TARBALL) $(BUILDDIR)/$(PRODUCT)-$(VERSION)/
.INTERMEDIATE:: $(BUILDDIR)/ls-lR.txt $(BUILDDIR)/VERSION
.PHONY: clean
