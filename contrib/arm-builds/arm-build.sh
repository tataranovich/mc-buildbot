#!/bin/sh

DSC_FILE="$1"
TARGET="$2"

build_target() {
    local _OS _DIST _ARCH
    _OS="$1"
    _DIST="$2"
    _ARCH="$3"
    echo -n "${_OS}-${_DIST}-${_ARCH}: "
    if [ ! -f "/var/cache/pbuilder/${_OS}-${_DIST}-${_ARCH}-base.tgz" ]; then
        sudo OS=$_OS DIST=$_DIST ARCH=$_ARCH pbuilder --create --configfile /etc/pbuilder/debbuilder >"logs/${_OS}-${_DIST}-${_ARCH}.create.log" 2>&1
    fi
    sudo OS=$_OS DIST=$_DIST ARCH=$_ARCH pbuilder --build --configfile /etc/pbuilder/debbuilder "$DSC_FILE" >"logs/${_OS}-${_DIST}-${_ARCH}.build.log" 2>&1
    if [ $? != 0 ]; then
        echo FAIL
    else
        echo OK
    fi
}

if [ -z "$DSC_FILE" ]; then
    echo "Specify package file name" >&2
    exit 1
fi

if [ ! -f "$DSC_FILE" ]; then
    echo "File not found: $DSC_FILE" >&2
    exit 1
fi

if [ -z "$TARGET" ]; then
    egrep -v '^($|\s+?#)' arm.list | while IFS=: read OS DIST ARCH
    do
        build_target $OS $DIST $ARCH
    done
else
    OS=$(echo "$TARGET" | cut -d: -f1)
    DIST=$(echo "$TARGET" | cut -d: -f2)
    ARCH=$(echo "$TARGET" | cut -d: -f3)
    build_target $OS $DIST $ARCH
fi
