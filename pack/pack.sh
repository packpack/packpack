#!/bin/bash

# Travis-CI wrapper for parallel builds

enabled_branches="master 1.6"
if [[ $enabled_branches =~ $4 ]] ; then
    echo 'Build started'
elif [ -n "$FORCE_BUILD" ] && [ "$FORCE_BUILD" == "true" ]; then
    echo 'Force build enabled for this branch'
else
    echo 'Build skipped(this branch is not for packaging)'
    exit 0
fi

repo_path=`echo $5 | sed -e "s/\./_/"`
if [ $# -eq 7 ] ; then
    make os=$2 dist=$3 branch=$4 product=$6 uri=$7 build-$1
    make os=$2 dist=$3 repo=$repo_path export-$1
else
    echo 'Build skipped'
    echo 'Usage:'
    echo './pack.sh [rpm/deb] <os> <distr> <branch> <repo>'
    echo 'Example: ./pack.sh rpm fedora 20 master user/test-repo'
    exit 0
fi
