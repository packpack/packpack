all: package

PACKDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

include $(PACKDIR)/config.mk
-include .build.mk

include $(PACKDIR)/tarball.mk
ifneq (,$(wildcard /etc/redhat-release))
include $(PACKDIR)/rpm.mk
else ifneq (,$(wildcard /etc/debian_version))
include $(PACKDIR)/deb.mk
else
prepare:
package: tarball
endif
