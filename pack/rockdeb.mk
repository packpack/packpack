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

ROCK_SPEC:=$(wildcard *.rockspec)
LUAROCKS_REPO:="https://github.com/tarantool/luarocks.git"

all: results

luarocks/src/bin/luarocks:
	git clone $(LUAROCKS_REPO) luarocks/
	test -f $@

results: luarocks/src/bin/luarocks
	rm -rf $@
	@echo "-------------------------------------------------------------------"
	@echo "Installing dependencies"
	@echo "-------------------------------------------------------------------"
	@echo
	./deps.sh $(ROCK_SPEC)
	@echo
	@echo "-------------------------------------------------------------------"
	@echo "Building packages"
	@echo "-------------------------------------------------------------------"
	./luarocks/src/bin/luarocks build --build-deb $(ROCK_SPEC) 2>&1 | tee build.log
	@echo
	@echo "-------------------------------------------------------------------"
	@echo "Copying packages"
	@echo "-------------------------------------------------------------------"
	mkdir -p $@.tmp/
	mv -f *.deb $@.tmp/
	mv -f build.log $@.tmp/
	mv $@.tmp $@
	@touch $@/.done
