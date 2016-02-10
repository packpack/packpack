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

# Tarantool: don't use long paths to avoid "AF_UNIX path too long"
RPMBUILDROOT=$(shell rpm -E %_topdir)
RPMDIST=$(shell rpm -E "%{dist}")
PKGVERSION=$(VERSION)-$(RELEASE)$(RPMDIST)
RPMSPECIN=$(PRODUCT).spec
RPMSPEC=$(RPMBUILDROOT)/SPECS/$(PRODUCT).spec
RPMTARBALL=$(RPMBUILDROOT)/SOURCES/$(TARBALL)
RPMSRC=$(RPMBUILDROOT)/SRPMS/$(PRODUCT)-$(PKGVERSION).src.rpm
RPM=$(RPMBUILDROOT)/RPMS/$(PRODUCT)-$(PKGVERSION).x86_64.rpm

all: results

$(RPMTARBALL):
	@echo "-------------------------------------------------------------------"
	@echo "Preparing RPM tarball"
	@echo "-------------------------------------------------------------------"
	mkdir -p $(RPMBUILDROOT)/SOURCES
	ln -s $(abspath $(TARBALL)) $@
	@echo

$(RPMSPEC): $(RPMSPECIN)
	@echo "-------------------------------------------------------------------"
	@echo "Preparing RPM spec"
	@echo "-------------------------------------------------------------------"
	@mkdir -p $(RPMBUILDROOT)/SPECS
	@cp $< $@.tmp
	sed -e 's/Version:\([ ]*\).*/Version: $(VERSION)/' \
		 -e 's/Release:\([ ]*\).*/Release: $(RELEASE)%{dist}/' \
		 -e 's/Source0:\([ ]*\).*/Source0: $(TARBALL)/' \
		 -e 's/%setup .*/%setup -q -n $(NAME)/' \
		 -i $@.tmp
	@grep -E "Version:|Release:|Source0|%setup" $@.tmp
	@mv -f $@.tmp $@
	@echo

$(RPMSRC): $(RPMSPEC) $(RPMTARBALL)
	@echo "-------------------------------------------------------------------"
	@echo "Building source package"
	@echo "-------------------------------------------------------------------"
	rpmbuild -bs $(RPMSPEC)
	@echo

.done: $(RPMSRC)
	@echo "-------------------------------------------------------------------"
	@echo "Installing dependecies"
	@echo "-------------------------------------------------------------------"
	sudo dnf builddep -y $< || sudo yum-builddep -y $<
	@echo
	@echo "-------------------------------------------------------------------"
	@echo "Building packages"
	@echo "-------------------------------------------------------------------"
	rpmbuild --rebuild --with backtrace $< 2>&1 | tee build.log
	@touch $@
	@echo

results: .done
	rm -rf $@
	@echo "-------------------------------------------------------------------"
	@echo "Copying packages"
	@echo "-------------------------------------------------------------------"
	mkdir -p $@.tmp/
	mv -f $(RPMBUILDROOT)/RPMS/*/*$(PRODUCT)*$(PKGVERSION).*.rpm $@.tmp/
	mv -f $(RPMSRC) $@.tmp/
	mv -f build.log $@.tmp/
	mv $@.tmp $@
	touch $@/.done

tarball: $(RPMTARBALL)
rpmsrc: $(RPMSRC)
spec: $(RPMSPEC)
rpm: .rpm

# Upload .src.rpm to koji.fedoraproject.org
koji: $(RPMSRC)
	$(CHROOT) koji build --scratch rawhide $<

clean:
	rm -f $(TARBALL) $(RPMSPEC) $(RPMTARBALL) $(RPMSRC) .rpm .done
