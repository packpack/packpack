#
# Packer for Rump Kernel
#

ifeq (,$(wildcard rump/Makefile))
$(error Can't find rump/Makefile)
endif

$(BUILDDIR)/$(PRODUCT)-$(VERSION)/rump/Makefile: $(BUILDDIR)/$(TARBALL)
	@echo "-------------------------------------------------------------------"
	@echo "Preparing build directory"
	@echo "-------------------------------------------------------------------"
	cd $(BUILDDIR) && tar xf $<
	test -d $(BUILDDIR)/$(PRODUCT)-$(VERSION)
	cp -pfR rump/ $(BUILDDIR)/$(PRODUCT)-$(VERSION)

prepare: $(BUILDDIR)/$(PRODUCT)-$(VERSION)/rump/Makefile

$(BUILDDIR)/$(PRODUCT): prepare
	@echo "-------------------------------------------------------------------"
	@echo "Building application"
	@echo "-------------------------------------------------------------------"
	$(MAKE) -C $(BUILDDIR)/$(PRODUCT)-$(VERSION)/rump/
	ls -l $(BUILDDIR)
	test -x $@

$(BUILDDIR)/$(PRODUCT)-$(VERSION).img: $(BUILDDIR)/$(PRODUCT)
	rumprun-bake hw_generic $@ $<
$(BUILDDIR)/$(PRODUCT)-$(VERSION)-hw_virtio.img: $(BUILDDIR)/$(PRODUCT)
	rumprun-bake hw_virtio $@ $<
$(BUILDDIR)/$(PRODUCT)-$(VERSION)-hw_virtio_scsi.img: $(BUILDDIR)/$(PRODUCT)
	rumprun-bake hw_virtio_scsi $@ $<

package: $(BUILDDIR)/$(PRODUCT)-$(VERSION).img \
         $(BUILDDIR)/$(PRODUCT)-$(VERSION)-hw_virtio.img \
         $(BUILDDIR)/$(PRODUCT)-$(VERSION)-hw_virtio_scsi.img
	@echo "------------------------------------------------------------------"
	@echo "Rumpkernels are ready"
	@echo "-------------------------------------------------------------------"
	@ls -1s $(BUILDDIR)/*.img

.PRECIOUS:: package
