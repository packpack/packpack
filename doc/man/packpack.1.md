# packpack(1) - simple tool to build RPM and Debian packages from git

## SYNOPSIS

    git_repo$ OS=ubuntu DIST=xenial packpack [TARGET]
    git_repo$ OS=debian DIST=sid packpack [TARGET]
    git_repo$ OS=fedora DIST=24 packpack [TARGET]
    git_repo$ OS=centos DIST=7 packpack [TARGET]

## DESCRIPTION

**PackPack** is a simple tool to build RPM and Debian packages from a git
repository:

* Fast reproducible builds using Docker containers
* Semantic versioning based on annotated git tags
* Support for all major Linux distributions as targets

## TARGETS

* tarball - pack a source tarball.
* prepare - prepare a build directory.
* package - build packages (default).
* clean   - remove all created files.

## ENVIRONMENT

**PackPack** settings can be overriden using environment variables:

* `OS` - target operating system name, e.g. `fedora` or `ubuntu`
* `DIST` - target distribution name, e.g `24` or `xenial`
* `BUILDDIR` - a directory used to store intermediate files and resulted
   packages (default is `./build`).
* `PRODUCT` - the name of software product, used for source tarball and
   source package, e.g. `tarantool`
* `VERSION` - semantic version of the software, e.g. 2.4.35
   (default is extracted for `git describe`).
* `RELEASE` - the number of times this version of the software has been
   packaged (default is 1).
*  `TARBALL_COMPRESSOR` - a compression algorithm to use, e.g. gz, bz2, xz
   (default is xz).
* `CHANGELOG_NAME`, `CHANGELOG_EMAIL`, `CHANGELOG_TEXT` - information
   used to bump version in changelog files.
* `DOCKER_REPO` - a Docker repository to use (default is `packpack/packpack`).

See the full list of available options and detailed configuration guide in
</usr/share/packpack/config.mk> configuration file.

## EXIT STATUS

**packpack** exits with a status of zero status on success.

## BUGS

See <https://github.com/packpack/packpack/issues>

## DOCUMENTATION

See <https://github.com/packpack/packpack>

## SEE ALSO

mock(1), pbuilder(1), git-buildpackage(1), rpm(1)
