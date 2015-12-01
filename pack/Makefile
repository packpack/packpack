all:
	make build-rpm

build-rpm:
	mkdir -p out
	cp build.sh out/
	docker run -v $(CURDIR)/out:/home/rpm/result tarantool/build:$(os)$(dist) sh /home/rpm/result/build.sh $(branch) $(uri) $(product)

export-src-rpm:
	package_cloud push $(repo)/$(os)/$(dist)/SRPMS/ out/*.src.rpm --skip-errors
	rm -f out/*.src.rpm
export-rpm:
	if [ `ls -1 out | grep .src.rpm | wc -l` != "0" ] ; then make export-src-rpm; fi
	package_cloud push $(repo)/$(os)/$(dist)/ out/*.rpm --skip-errors
	rm -f out/*.rpm
build-deb:
	mkdir -p out
	cp build_deb.sh out/
	cp build_py.py out/
	docker run -v $(CURDIR)/out:/home/deb/result tarantool/build:$(os)-$(dist) sh /home/deb/result/build_deb.sh $(os) $(dist) $(branch) $(product) $(uri)
export-dsc:
	package_cloud push $(repo)/$(os)/$(dist)/ out/*.dsc --skip-errors
	rm -f out/*.dsc
	rm -f out/*.gz
	rm -f out/*.xz
export-deb:
	package_cloud push $(repo)/$(os)/$(dist)/ out/*.deb --skip-errors
	rm -f out/*.deb
	if [ `ls -1 out | grep .dsc | wc -l` != "0" ] ; then make export-dsc; fi
clean:
	docker rm `docker ps -aq`
	rm -rf out
