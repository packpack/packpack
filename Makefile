PACKVERSION := $(shell cat VERSION 2>/dev/null || git describe --long)

prefix ?= /usr
bindir ?= $(prefix)/bin
datadir ?= $(prefix)/share

all:

$(DESTDIR)$(bindir)/:
	mkdir -p $@
$(DESTDIR)$(bindir)/packpack: packpack $(DESTDIR)$(bindir)/
	install -pm0755 $< $@
	sed -i $@ \
		-e 's#PACKVERSION=.*#PACKVERSION=$(PACKVERSION)#' \
		-e 's#PACKDIR=.*#PACKDIR=$(datadir)/packpack#'

$(DESTDIR)$(datadir)/packpack/:
	mkdir -p $@
$(DESTDIR)$(datadir)/packpack/%: pack/% $(DESTDIR)$(datadir)/packpack/
	install -pm0644 pack/$(notdir $@) $(dir $@)

install: $(DESTDIR)$(bindir)/packpack \
         $(DESTDIR)$(datadir)/packpack/Makefile \
         $(DESTDIR)$(datadir)/packpack/config.mk \
         $(DESTDIR)$(datadir)/packpack/tarball.mk \
         $(DESTDIR)$(datadir)/packpack/deb.mk \
         $(DESTDIR)$(datadir)/packpack/rpm.mk
