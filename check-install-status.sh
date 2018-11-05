#!/bin/bash

if [ "$1" == "--stat" ]; then
    DIFF_OPTS='--brief'
else
    DIFF_OPTS='-u'
fi

BASE_DIR=$(dirname $(readlink -f "$0"))
pushd $PWD

cd $BASE_DIR
find -maxdepth 1 -type f ! -name check-install-status.sh -exec diff $DIFF_OPTS '{}' '/home/buildbot/{}' \;

cd $BASE_DIR/contrib
find -maxdepth 1 -type f -exec diff $DIFF_OPTS '{}' '/home/andrey/bin/{}' \;

cd $BASE_DIR/contrib/apt-ftparchive
find -maxdepth 1 -type f -exec diff $DIFF_OPTS '{}' '/home/andrey/{}' \;

cd $BASE_DIR/contrib/pbuilder
find -maxdepth 1 -type f -exec diff $DIFF_OPTS '{}' '/etc/pbuilder/{}' \;

popd
