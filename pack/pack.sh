# Travis-CI wrapper for parallel builds

enabled_branches="master 1.6 1.7"
if [[ $enabled_branches =~ $4 ]] ; then
    echo 'Build started'
else
    echo 'Build skipped(this branch is not for packaging)'
    exit 0
fi

if [ $# -eq 5 ] ; then
    make build-$1 os=$2 dist=$3 branch=$4
    make export-$1 os=$2 dist=$3 repo=$5
elif [ $# -eq 7 ] ; then
    make os=$2 dist=$3 branch=$4 product=$6 uri=$7 build-$1
    make os=$2 dist=$3 repo=$5 export-$1
else
    echo 'Build skipped'
    echo 'Usage:'
    echo './pack.sh [rpm/deb] <os> <distr> <branch> <repo>'
    echo 'Example: ./pack.sh rpm fedora 20 master user/test-repo'
    exit 0
fi
