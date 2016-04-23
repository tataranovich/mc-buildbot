#!/bin/sh

DSC_FILE="$1"
if [ -z "$DSC_FILE" ]; then
    echo "Specify package file name" >&2
    exit 1
fi

egrep -v '^($|\s+?#)' arm.list | while IFS=: read OS DIST ARCH
do
    echo -n "$OS-$DIST-$ARCH: "
    sudo OS=$OS DIST=$DIST ARCH=$ARCH pbuilder --build --configfile /etc/pbuilder/debbuilder "$DSC_FILE" >"build-${OS}-${DIST}-${ARCH}.log" 2>&1
    if [ $? != 0 ]; then
        echo FAIL
    else
        echo OK
    fi
done
