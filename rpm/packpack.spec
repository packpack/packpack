Name: packpack
Version: 1.0.0
Release: 1%{?dist}
Summary: Simple tool to build RPM and Debian packages from git repository
License: BSD
URL: https://github.com/packpack/packpack
Source0: https://github.com/packpack/packpack/archive/%{version}/packpack-%{version}.tar.gz
BuildArch: noarch
BuildRequires: coreutils
BuildRequires: sed
BuildRequires: make
Requires: bash
Requires: coreutils
Requires: docker >= 1.5

%description
 PackPack is a simple tool to build RPM and Debian packages
 from git repository using Docker:

 * Fast reproducible builds using Docker containers
 * Semantic versioning based on annotated git tags
 * Support for all major Linux distributions as targets

%prep
%setup -q -n %{name}-%{version}

%install
%make_install

%post
# Fix security context for SELinux
# http://stackoverflow.com/questions/24288616/permission-denied-on-accessing-host-directory-in-docker
chcon -Rt svirt_sandbox_file_t %{_datarootdir}/packpack/ || :

%files
%{_bindir}/packpack
%{_datarootdir}/packpack/*
%doc README.md
%{!?_licensedir:%global license %doc}
%license LICENSE

%changelog
* Sun Oct 30 2016 Roman Tsisyk <roman@tarantool.org> 1.0.0-1
- Initial release
