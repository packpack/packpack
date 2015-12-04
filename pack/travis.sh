#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

if [ -n "$PACK" ] && [ "$PACK" != "none" ]; then
    [ -z $OS ] && echo "Missing OS" && exit 1
    [ -z $DIST ] && echo "Missing DIST" && exit 1
    echo 'Test skipped(packaging mode)'
    cd ${SCRIPT_DIR}
    ./pack.sh $PACK $OS $DIST $TRAVIS_BRANCH $OUT_REPO $PROJECT $GIT_REPO
else
    echo 'Preparing tests'
    echo 'Generic tests not implemented..'
fi
