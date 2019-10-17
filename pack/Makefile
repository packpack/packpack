all: package

PACKDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

include $(PACKDIR)/config.mk
-include .build.mk

include $(PACKDIR)/tarball.mk
ifneq (,$(wildcard /usr/rumprun-*))
include $(PACKDIR)/rumprun.mk
else ifneq (,$(wildcard /etc/redhat-release))
include $(PACKDIR)/rpm.mk
else ifneq (,$(wildcard /etc/debian_version))
include $(PACKDIR)/deb.mk
else ifneq (,$(wildcard /etc/alpine-release))
include $(PACKDIR)/apk.mk
else ifneq (,$(shell grep "^ID=\"opensuse-leap\"" /etc/os-release))
include $(PACKDIR)/rpm.mk
else
prepare:
package: tarball
endif
