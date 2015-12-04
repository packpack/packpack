#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

git submodule update --init --recursive
gem install package_cloud
if [ -n "$PACK" ] && [ "$PACK" != "none" ]; then
    [ -z $OS ] && echo "Missing OS" && exit 1
    [ -z $DIST ] && echo "Missing DIST" && exit 1
    [ -z $TRAVIS_REPO_SLUG ] && echo "Missing TRAVIS_REPO_SLUG" && exit 1
    [ -z $TRAVIS_BRANCH ] && echo "Missing TRAVIS_BRANCH" && exit 1

    TRAVIS_REPO_USER=$(echo $TRAVIS_REPO_SLUG | cut -d '/' -f 1)
    TRAVIS_REPO_NAME=$(echo $TRAVIS_REPO_SLUG | cut -d '/' -f 2)
    [ -z $OUT_REPO ] && OUT_REPO="${TRAVIS_REPO_USER}/${TRAVIS_BRANCH}"
    GIT_REPO=https://github.com/$TRAVIS_REPO_SLUG.git

    echo 'Test skipped(packaging mode)'
    cd ${SCRIPT_DIR}
    ./pack.sh $PACK $OS $DIST $TRAVIS_BRANCH $OUT_REPO $TRAVIS_REPO_NAME \
        $GIT_REPO
else
    echo 'Preparing tests'
    if [ -f test.sh ]; then
        echo 'Found test script'
        bash test.sh
    fi
fi
