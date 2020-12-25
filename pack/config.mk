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
# The output of `git describe` to generate VERSION, ABBREV and
# ./VERSION file.
#
DESCRIBE := $(shell git describe --long --always)

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
VERSION ?= $(shell echo $(DESCRIBE) | sed -n 's/^\([0-9\.]*\)-\([0-9]*\)-\([a-z0-9]*\)/\1.\2/p')
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
# git abbreviation with 'g' prefix, 7+ hexadecimal digits
#
# From git 2.11.0 changelog:
# The default abbreviation length, which has historically been 7, now
#   scales as the repository grows, using the approximate number of
#   objects in the repository and a bit of math around the birthday
#   paradox.  The logic suggests to use 12 hexdigits for the Linux
#   kernel, and 9 to 10 for Git itself.
#
ABBREV ?= $(shell echo $(DESCRIBE) | sed -n 's/^\([0-9\.]*\)-\([0-9]*\)-\([a-z0-9]*\)/\3/p')

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

#
# A comma separated list of environment variables to preserve.
#
PRESERVE_ENVVARS ?=
