#!/bin/bash
if [ $PACK != 'none' ]; then
    echo 'Test skipped(packaging mode)'
    cd build/pack
    bash pack.sh $PACK $OS $DIST $TRAVIS_BRANCH $OUT_REPO $PROJECT $GIT_REPO
else
    echo 'Preparing tests'
    echo 'Generic tests not implemented..'
fi
