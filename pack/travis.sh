#!/bin/bash
# set -x

READLINK="readlink -f"
if [ ! -z $(which realpath) ]; then
    READLINK="realpath"
fi

SCRIPT=$($READLINK $0)
SCRIPT_DIR=$($READLINK $(dirname ${SCRIPT})/../)

ENABLED_BRANCHES="${ENABLED_BRANCHES:-master 1.6 1.7}"
DOCKER_REPO="tarantool/build"

usage() {
    echo "$1"
    echo
    echo "Usage"
    echo "====="
    echo
    echo "PACK=rpm OS=fedora DIST=rawhide $0"
    echo
    echo "Please refer to README.md for additional information"
    echo
    exit 1
}

decrypt_travis_key() {
    DECRYPTED_KEY_PATH=${DECRYPTED_KEY_PATH:-"extra/deploy_key"}
    ENCRYPTED_KEY_PATH=${ENCRYPTED_KEY_PATH:-"${DECRYPTED_KEY_PATH}.enc"}
    if [ ! -f "$DECRYPTED_KEY_PATH" ]; then
        if [ -z "${ENCRYPTION_LABEL}" ]; then
            echo "Failed to decrypt deployment key (not on Travis-CI)"
            return
        fi
        ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
        ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
        ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
        ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
        openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV \
            -in "$ENCRYPTED_KEY_PATH" -out "$DECRYPTED_KEY_PATH" -d
        chmod 600 $DECRYPTED_KEY_PATH
    fi
    eval `ssh-agent -s`
    ssh-add $DECRYPTED_KEY_PATH
}

git submodule update --init --recursive
if [ $? -ne 0 ]; then
    echo "Failed to update submodules"
    exit -1
fi

if [ -z "${VERSION}" ]; then
    VERSION=$(git describe --long --always)
fi

if [ -z "${VERSION}" ]; then
    echo "Failed to get version from git describe"
    exit -1
fi

# Save git describe result to VERSION file
echo ${VERSION} > VERSION

if [ "$TRAVIS_OS_NAME" == "osx" ]; then
    echo "Increase the maximum number of open file descriptors on macOS"
    sudo launchctl limit maxfiles 1000000 1000000
fi

if [ "$PACK" == "none" ]; then
    echo 'Test mode'
    if [ -f test.sh ]; then
        echo 'Found test.sh script'
        exec bash test.sh
    elif [ -f .build.mk ]; then
        echo 'Found .build.mk script'
        exec make -f .build.mk travis_test_${TRAVIS_OS_NAME}
    fi
    exit 0
elif [ "$PACK" == "coverage" ]; then
    echo 'Coverage mode'
    if [ ! -f .build.mk ]; then
        echo "Missing .build.mk"
        exit 1
    fi

    sudo apt-get -q -y install lcov
    [ $? -eq 0  ] || exit $?

    make -f .build.mk travis_coverage
    [ $? -eq 0  ] || exit $?

    ${SCRIPT_DIR}/coverage list
    [ $? -eq 0  ] || exit $?

    if [ -n "${COVERALLS_TOKEN}"  ]; then
        gem install coveralls-lcov
        ${SCRIPT_DIR}/coverage upload
        [ $? -eq 0  ] || exit $?
        exit 0
    fi
    exit 0
elif [ -n "$PACK" -a -f "$PACK" ]; then
    echo "Executing $PACK script"
    bash $PACK
    exit 0
fi

echo 'Packaging mode'

[ -n "${OS}" ] || [ "$PACK" == "source" ] || usage "Missing OS"
if [ "${OS}" == "el" ]; then
    OS=centos
fi
[ -n "${DIST}" ] || [ "$PACK" == "source"  ] || usage "Missing DIST"
[ -x ${SCRIPT_DIR}/build ] || usage "Missing ./build"

if [ -n "${TRAVIS_REPO_SLUG}" ]; then
    echo "Travis CI detected"
    if [ -z "${PRODUCT}" ]; then
        PRODUCT=$(echo $TRAVIS_REPO_SLUG | cut -d '/' -f 2)
    fi
    BRANCH="${TRAVIS_BRANCH}"
    if [[ ! ${ENABLED_BRANCHES} =~ "${BRANCH}" ]] ; then
        echo "Build skipped - the branch ${BRANCH} is not for packaging"
        exit 0
    fi
    TRAVIS_REPO_USER=$(echo $TRAVIS_REPO_SLUG | cut -d '/' -f 1)
    if [ -z "${PACKAGECLOUD_REPO}" ]; then
        PACKAGECLOUD_REPO=${TRAVIS_REPO_USER}/$(echo ${BRANCH} | sed -e "s/\./_/")
        if [ "${TRAVIS_REPO_USER}" == "tarantool" ] && [ "${BRANCH}" == "master" ]; then
            # Upload all master branches from tarantool/X repos to tarantool/1_6
            PACKAGECLOUD_REPO="tarantool/1_6"
        fi
    fi
    if [ -z "${REPO_PREFIX}" ]; then
        REPO_PREFIX=${BRANCH}
        if [ "${TRAVIS_REPO_USER}" == "tarantool" ] && [ "${BRANCH}" == "master" ]; then
            # Upload all master branches from tarantool/X repos to tarantool/1_6
            REPO_PREFIX="1.6"
        fi
    fi
else
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [ -z "${BRANCH}" ]; then
        echo "git rev-parse failed"
        exit -1
    fi
    if [ -z "${REPO_PREFIX}" ]; then
        REPO_PREFIX=${BRANCH}
    fi
    if [ -z "${PACKAGECLOUD_REPO}" ]; then
        PACKAGECLOUD_REPO=${USER}/$(echo ${BRANCH} | sed -e "s/\./_/")
    fi
    if [ -z "${PRODUCT}" ]; then
        origin=$(git config --get remote.origin.url)
        name=$(basename "$origin")
        PRODUCT="${name%.*}"
    fi
fi

if [ -n "${FTP}" ]; then
    FTP_USERPASSWORD=$(echo ${FTP} | cut -d '@' -f 1)
    FTP_HOST=$(echo ${FTP} | cut -d '@' -f 2)
    FTP_USER=$(echo ${FTP_USERPASSWORD} | cut -d ':' -f 1)
    FTP_PASSWORD=$(echo ${FTP_USERPASSWORD} | cut -d ':' -f 2)
fi

if [ -n "${SFTP}" ]; then
    SFTP_USERPASSWORD=$(echo ${SFTP} | cut -d '@' -f 1)
    SFTP_HOST=$(echo ${SFTP} | cut -d '@' -f 2)
    SFTP_USER=$(echo ${SFTP_USERPASSWORD} | cut -d ':' -f 1)
    SFTP_PASSWORD=$(echo ${SFTP_USERPASSWORD} | cut -d ':' -f 2)
fi

[ -n "${PRODUCT}" ] || usage "Missing PRODUCT"

if echo "${DIST}" | grep -c '^[0-9]\+$' > /dev/null; then
    # Numeric dist, e.g. centos6 or fedora23
    OSDIST="${OS}${DIST}"
else
    # Non-numeric dist, e.g. debian-sid, ubuntu-precise, etc.
    OSDIST="${OS}-${DIST}"
fi

DOCKER_TAG=${DOCKER_REPO}:${OSDIST}
DOCKERDO="${SCRIPT_DIR}/dockerdo ${DOCKER_TAG}"

echo
echo '-----------------------------------------------------------'
echo "Product:          ${PRODUCT}"
echo "Version:          ${VERSION} (branch ${BRANCH})"
if ! { [ -z "$OS" ] || [ -z "$DIST" ]; } then
    echo "Target:           ${OSDIST}"
    echo "Docker Image:     ${DOCKER_TAG}"
fi

if [ -n "${FTP}" ]; then
    echo "FTP host:         ${FTP_HOST} (repo ${REPO_PREFIX})"
else
    echo "FTP host:         skipped - missing FTP"
fi

if [ -n "${SFTP}" ]; then
    echo "SFTP host:        ${SFTP_HOST} (repo ${REPO_PREFIX})"
else
    echo "SFTP host:        skipped - missing SFTP"
fi

if [ -n "${PACKAGECLOUD_TOKEN}" ]; then
    echo "PackageCloud:     ${PACKAGECLOUD_REPO}"
else
    echo "PackageCloud:     skipped - missing PACKAGECLOUD_TOKEN"
fi
echo '-----------------------------------------------------------'
echo

# Clean buildroot
echo "Cleaning buildroot"
rm -rf buildroot/
git clean -f -X -d
echo ${VERSION} > VERSION

ROCKSPEC=$(ls -1 *.rockspec rockspec/*-scm*.rockspec 2> /dev/null)

echo "Make version is:"
make --version

if ! { [ -z "$OS" ] || [ -z "$DIST" ]; } then
    RESULTS=${SCRIPT_DIR}/root/${PACK}-${OSDIST}/results/
else
    RESULTS=${SCRIPT_DIR}/root/
fi

if [ "${PACK}" == "rpm" ]; then
    if [ -f "rpm/${PRODUCT}.spec" ] ; then
        echo "Found RPM: rpm/${PRODUCT}.spec"
        echo ${SCRIPT_DIR}/build PRODUCT=${PRODUCT} \
            DOCKER_REPO=${DOCKER_REPO} ${OSDIST}
        ${SCRIPT_DIR}/build PRODUCT=${PRODUCT} \
            DOCKER_REPO=${DOCKER_REPO} ${OSDIST}
    elif [ -f "${ROCKSPEC}" ]; then
        RESULTS=${SCRIPT_DIR}/root/rockrpm-${OSDIST}/results/
        ${SCRIPT_DIR}/build PRODUCT=${PRODUCT} \
            DOCKER_REPO=${DOCKER_REPO} rock-${OSDIST}
    else
        echo "Can't find RPM spec"
        exit 1
    fi
elif [ "${PACK}" == "deb" ]; then
    if [ -d "debian/" ]; then
        echo "Found debian/"
        ${SCRIPT_DIR}/build PRODUCT=${PRODUCT} \
            DOCKER_REPO=${DOCKER_REPO} ${OSDIST}
    elif [ -f "${ROCKSPEC}" ]; then
        RESULTS=${SCRIPT_DIR}/root/rockdeb-${OSDIST}/results/
        ${SCRIPT_DIR}/build PRODUCT=${PRODUCT} \
            DOCKER_REPO=${DOCKER_REPO} rock-${OSDIST}
    else
        echo "Can't find debian/"
        exit 1
    fi
elif [ "${PACK}" == "source" ]; then
    ${SCRIPT_DIR}/build PRODUCT=${PRODUCT} tarball
else
    usage "Invalid PACK value"
fi

if [ $? -ne 0 ]; then
    echo "Build failed"
    exit -1
fi

if [ -n "${FTP_HOST}" ]; then
    echo "Exporting packages to FTP ${FTP_HOST}/${REPO_PREFIX}"
    #sudo apt-get install ftp
    cd ${RESULTS}
    rm -f *.md5sum ftp.log
    cat > ftpscript.txt <<-EOF
open ${FTP_HOST}
user ${FTP_USER} ${FTP_PASSWORD}
pass
EOF
    if [ "${PACK}" == "rpm" ]; then
        echo "cd /${REPO_PREFIX}/${OS}/${DIST}/x86_64/Packages/" >> ftpscript.txt
        for f in *[!src].rpm; do
            if [ ! -f $f ]; then continue; fi
            md5sum $f > $f.md5sum
            echo "put $f.md5sum" >> ftpscript.txt
            echo "put $f $f.tmp" >> ftpscript.txt
            echo "rename $f.tmp $f" >> ftpscript.txt
        done
        echo "cd /${REPO_PREFIX}/${OS}/${DIST}/SRPMS/Packages/" >> ftpscript.txt
        for f in *.src.rpm; do
            if [ ! -f $f ]; then continue; fi
            md5sum $f > $f.md5sum
            echo "put $f.md5sum" >> ftpscript.txt
            echo "put $f $f.tmp" >> ftpscript.txt
            echo "rename $f.tmp $f" >> ftpscript.txt
        done
    elif [ "${PACK}" == "deb" ]; then
        echo "cd /${REPO_PREFIX}/${OS}/incoming/${DIST}" >> ftpscript.txt
        for f in *.deb *.dsc *.changes *.orig.tar.* *.debian.tar.*; do
            if [ ! -f $f ]; then continue; fi
            md5sum $f > $f.md5sum
            echo "put $f.md5sum" >> ftpscript.txt
            echo "put $f $f.tmp" >> ftpscript.txt
            echo "rename $f.tmp $f" >> ftpscript.txt
        done
    elif [ "${PACK}" == "source" ]; then
        echo "cd /${REPO_PREFIX}/src/" >> ftpscript.txt
        for f in *.tar.* *.zip *.rar; do
            if [ ! -f $f ]; then continue; fi
            echo "put $f.md5sum" >> ftpscript.txt
            echo "put $f $f.tmp" >> ftpscript.txt
            echo "rename $f.tmp $f" >> ftpscript.txt
        done
    fi
    echo "--"
    tail -n +3 ftpscript.txt
    echo "--"
    ftp -i -n -v < ftpscript.txt | tail -n +3 | tee ftp.log
    echo "--"
    grep failed ftp.log > /dev/null
    rm -f ftpscript.txt
    if [ $? -eq 0 ]; then
        echo "(!) FTP Upload failed :("
        exit -1
    else
        echo "OK!"
    fi
fi

if [ -n "${SFTP_HOST}" ]; then
    echo "Exporting packages to SFTP ${SFTP_HOST}/${REPO_PREFIX}"
    decrypt_travis_key
    cd ${RESULTS}
    rm -f *.md5sum sftp.log sftpscript.txt || break
    touch sftpscript.txt
    if [ "${PACK}" == "rpm" -a -n "${SFTP_UPLOAD_RPM}" ]; then
        echo "cd /${REPO_PREFIX}/${OS}/${DIST}/x86_64/Packages/" >> sftpscript.txt
        for f in *[!src].rpm; do
            if [ ! -f $f ]; then continue; fi
            md5sum $f > $f.md5sum
            echo "put $f.md5sum" >> sftpscript.txt
            echo "put $f $f.tmp" >> sftpscript.txt
            echo "rename $f.tmp $f" >> sftpscript.txt
        done
        echo "cd /${REPO_PREFIX}/${OS}/${DIST}/SRPMS/Packages/" >> sftpscript.txt
        for f in *.src.rpm; do
            if [ ! -f $f ]; then continue; fi
            md5sum $f > $f.md5sum
            echo "put $f.md5sum" >> sftpscript.txt
            echo "put $f $f.tmp" >> sftpscript.txt
            echo "rename $f.tmp $f" >> sftpscript.txt
        done
    elif [ "${PACK}" == "deb"  -a -n "${SFTP_UPLOAD_DEB}" ]; then
        echo "cd /${REPO_PREFIX}/${OS}/incoming/${DIST}" >> sftpscript.txt
        for f in *.deb *.dsc *.changes *.orig.tar.* *.debian.tar.*; do
            if [ ! -f $f ]; then continue; fi
            md5sum $f > $f.md5sum
            echo "put $f.md5sum" >> sftpscript.txt
            echo "put $f $f.tmp" >> sftpscript.txt
            echo "rename $f.tmp $f" >> sftpscript.txt
        done
    elif [ "${PACK}" == "source" -a -n "${SFTP_UPLOAD_SOURCE}" ]; then
        echo "cd /${REPO_PREFIX}/src/" >> sftpscript.txt
        for f in *.tar.*; do
            if [ ! -f $f ]; then continue; fi
            md5sum $f > $f.md5sum
            echo "put $f.md5sum" >> sftpscript.txt
            echo "put $f $f.tmp" >> sftpscript.txt
            echo "rename $f.tmp $f" >> sftpscript.txt
        done
    fi
    echo "-- sftpscript.txt content"
    cat sftpscript.txt
    echo "-- output of task"
    cat sftpscript.txt | sftp -o "StrictHostKeyChecking no" ${SFTP_USER}@${SFTP_HOST} -v 2>&1 | tee sftp.log
    echo "-- task result"
    grep "failed\|Permission denied\|No such file or directory" sftp.log > /dev/null
    if [ $? -eq 0 ]; then
        echo "(!) SFTP Upload failed :("
        rm -f sftpscript.txt
        exit -1
    else
        echo "OK!"
    fi
    rm -f sftpscript.txt
fi

if [ -n "${PACKAGECLOUD_TOKEN}" ]; then
    echo "Exporting packages to packagecloud.io repo ${PACKAGECLOUD_REPO}"
    if [ "${OS}" == "centos" ]; then
        # Packagecloud doesn't support CentOS, but supports RHEL
        echo "PackageCloud doesn't support ${OSDIST}"
        echo "Using repository for RHEL"
        OS=el
    elif [ "${DIST}" == "rawhide" ] || [ "${DIST}" == "sid" ]; then
        echo "PackageCloud doesn't support ${OSDIST}"
        echo "Skipping..."
        exit 0
    fi
    gem install package_cloud
    if [ "${PACK}" == "rpm" ]; then
        package_cloud push ${PACKAGECLOUD_REPO}/${OS}/${DIST}/ \
            ${RESULTS}/*[!src].rpm --skip-errors
        if [ "$(echo ${RESULTS}/*.src.rpm)" != "${RESULTS}/*.src.rpm" ]; then
            package_cloud push ${PACKAGECLOUD_REPO}/${OS}/${DIST}/SRPMS/ \
                ${RESULTS}/*.src.rpm --skip-errors
        fi
    elif [ "${PACK}" == "deb" ]; then
        package_cloud push ${PACKAGECLOUD_REPO}/${OS}/${DIST}/ \
            ${RESULTS}/*.deb --skip-errors
        if [ "$(echo ${RESULTS}/*.dsc)" != "${RESULTS}/*.dsc" ]; then
            package_cloud push ${PACKAGECLOUD_REPO}/${OS}/${DIST}/ \
                ${RESULTS}/*.dsc --skip-errors
        fi
    fi
fi
