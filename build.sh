#!/bin/sh

# Defaults
BUILD=1.0.0
SOURCEDIR=${SOURCEDIR:-${PWD}}
BUILDDIR=${BUILDDIR:-${PWD}/build}
PACKDIR=$(cd $(dirname $0) && pwd)/pack
DISTRO=${DISTRO:-ubuntu-xenial}
DOCKER_REPO=${DOCKER_REPO:-tarantool/build}

version() {
    echo "Tarantool/Build ${BUILD}"
}

usage() {
    echo "# Tarantool/Build ${BUILD}"
    echo ""
    echo "Usage: DISTRO=ubuntu-xenial $0 [TARGET..]"
    echo ""
    echo "## Available Targets"
    echo ""
    echo " * tarball - pack a source tarball"
    echo " * prepare - prepare a build directory"
    echo " * package - build packages (default)"
    echo " * clean   - remove all created files"
    echo ""
    echo "## Environment Variables"
    echo ""
    echo " * PRODUCT - the name of software product, e.g. 'tarantool'"
    echo " * DISTRO - the name of distribution (${DISTRO})"
    echo " * SOURCEDIR - source directory with git repository (${SOURCEDIR})"
    echo " * BUILDDIR - directory used for out-of-source build (${BUILDDIR})"
    echo " * DOCKER_REPO - Docker repository to use (${DOCKER_REPO})"
    echo ""
    echo "See also ${PACKDIR}/config.mk"
    echo ""
    echo "The actual list of distribution is available on Docker Hub:"
    echo ""
    echo "   https://hub.docker.com/r/${DOCKER_REPO}/tags/"
    echo ""
    echo "## Documentation"
    echo ""
    echo " * See https://github.com/tarantool/build"
    echo ""
}

case "$1" in
    -v|--version)
        version
        exit 0
    ;;
    -h|--help)
        usage
        exit 1
        ;;
    *) ;;
esac

set -e


#
# Create an entry point for Docker to allow builds from non-root user
#
mkdir -p ${BUILDDIR}
echo \
    "#!/bin/sh\n"\
    "sudo useradd -u $(id -u) $USER\n"\
    "sudo usermod -a -G sudo $USER 2>/dev/null || true\n"\
    "sudo usermod -a -G wheel $USER 2>/dev/null || true\n"\
    "sudo usermod -a -G adm $USER 2>/dev/null || true\n"\
    "sudo -E -u $USER \$@\n"\
    > ${BUILDDIR}/userwrapper.sh
chmod a+x ${BUILDDIR}/userwrapper.sh

#
# Save defined configuration variables to ./env file
#
env | grep -E "PRODUCT|VERSION|RELEASE|TARBALL_|CHANGELOG_" > ${BUILDDIR}/env

#
# Start Docker
#
set -ex
docker run \
        --volume "${PACKDIR}:/pack:ro" \
        --volume "${SOURCEDIR}:/source:ro" \
        --volume "${BUILDDIR}:/build" \
        --env-file ${BUILDDIR}/env \
        --workdir /pack \
        --rm=true \
        --entrypoint=/build/userwrapper.sh \
        -e CCACHE_DIR=/ccache \
        --volume "${HOME}/.cache:/ccache" \
        ${DOCKER_REPO}:${DISTRO} \
        make SOURCEDIR=/source BUILDDIR=/build -j $@

# vim: filetype=sh tabstop=4 shiftwidth=4 softtabstop=4 expandtab
