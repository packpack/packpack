#
# Common configuration options
#

# Build directory
BUILDDIR?=$(CURDIR)/build

#
# The name of the software product.
#
ifeq ($(PRODUCT),) # Guess from Debian package
PRODUCT := $(word 2,$(shell grep Source: debian/control 2>/dev/null))
endif
ifeq ($(PRODUCT),) # Guess from RPM package
PRODUCT := $(word 2,$(shell grep Name: rpm/*.spec 2>/dev/null))
endif
ifeq ($(PRODUCT),) # Guess from git repository name
PRODUCT := $(shell git config --get remote.origin.url | \
					sed -e 's/.*\///' -e 's/.git$$//')
endif
ifeq ($(PRODUCT),) # Guess from directory name
PRODUCT := $(shell basename $(CURDIR))
endif

#
# Semantic version of the software, e.g. 2.4.35.
#
# Major and minor versions are extracted from the closest git tag.
# Patch level is the number of additional commits after this tag.
# For example, if `git describe` reports 1.0-3-g5c26e8b, then
# major is 1, minor is 2 and patch level is 3. SHA1 is ignored.
#
# See git-describe(1) for detailed explanation of the tag search
# strategy and algorithm.
#
# Sic: please follow Semantic Versioning (http://semver.org),
# Debian policies and Fedora guidelines then planning your releases.
#
VERSION ?= $(shell git describe --long --always | sed -n 's/^\([0-9\.]*\)-\([0-9]*\)-\([a-z0-9]*\)/\1.\2/p')
ifeq ($(VERSION),) # Fallback
VERSION := 0.0.1
endif

# The number of times this version of the software has been packaged.
# This feature is not implemented yet, therefore value is always set to 1.
#
# Sic: Both Debian policies and Fedora guidelines discourage 0 value.
#
RELEASE ?= 1

#
# git hash without 'g' prefix, 7 hexadecimal digits
#
REVISION ?= $(shell git rev-parse HEAD)

# Name, email and text for changelog entry
CHANGELOG_NAME ?= PackPack
CHANGELOG_EMAIL ?= build@tarantool.org
CHANGELOG_TEXT ?= Automated build

# Extra arguments for tar
TARBALL_EXTRA_ARGS ?=

# Extra files to include into source tarball
TARBALL_EXTRA_FILES ?=

# Compression method
TARBALL_COMPRESSOR ?= xz

#
# Specifies the number of GNU make jobs (commands) to run simultaneously.
#
SMPFLAGS ?= -j$(shell nproc)
