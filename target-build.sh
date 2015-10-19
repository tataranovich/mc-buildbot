#!/bin/bash

SUPPORTED_TARGETS="squeeze-i386 squeeze-amd64 wheezy-i386 wheezy-amd64 jessie-i386 jessie-amd64 stretch-i386 stretch-amd64 sid-i386 sid-amd64 precise-i386 precise-amd64 trusty-i386 trusty-amd64 vivid-i386 vivid-amd64"

UNCLEAN_BUILD=0

die() {
    warn "$1"
	exit 1
}

warn() {
    if [ ! -z "$1" ]; then
		echo "BUILDBOT: $1" >&2
	fi
}

show_usage() {
	echo "Example: target-build.sh --src package_1.0-1.dsc --target lenny-i386 --repository main/p/package --output ~/tmp/20120628"
	exit 1
}

parse_cmdline() {
	if [ $# -eq 0 ]; then
		show_usage
	fi
	set -- `getopt -u --longoptions="src: target: repository: output:" -- -- "$@"` || show_usage
	while [ $# -gt 0 ]
	do
		case "$1" in
			--src)
				BUILD_SRC="$2"
				shift
				;;
			--target)
				BUILD_TARGET=`echo "$2" | sed -e 's/,/\ /g'`
				shift
				;;
			--repository)
				BUILD_REPO_PATH="$2"
				shift
				;;
			--output)
				BUILD_OUTPUT="$2"
				shift
				;;
			--)
				shift
				break
				;;
			*)
				break
		esac
		shift
	done
}

do_all_preparations() {
	if [ ! -f "$BUILD_SRC" ]; then
		if [ ! -z "$BUILD_SRC" ]; then
			die "Unable to find file: $BUILD_SRC"
		else
			echo "You must provide path to DSC file"
			show_usage
		fi
	fi

	if [ -z "$BUILD_TARGET" ]; then
		echo "You must provide build target"
		show_usage
	fi

	if [ -z "$BUILD_REPO_PATH" ]; then
		echo "You must provide repository path where to store build results"
		show_usage
	fi

	if [ -z "$BUILD_OUTPUT" ]; then
		echo "You must provide repository output path"
		show_usage
	fi

	if [ "$BUILD_TARGET" = "all" ]; then
		for i in $SUPPORTED_TARGETS
		do
			if [ ! -f "/etc/pbuilder/$i" ]; then
				die "Unable to find pbuilder config for target: $i"
			else
				# Check if target not updated for 7 days and update it
				if [ `find "/var/cache/pbuilder/base-${i}.tgz" -type f -mtime -7 | wc -l` = 0 ]; then
					echo "Target $i not updated last 7 days - updating it"
					sudo pbuilder --update --override-config --configfile "/etc/pbuilder/$i" || echo "Failed to update target: $i"
				fi
			fi
		done
	else
		for i in $BUILD_TARGET
		do
			if [ ! -f "/etc/pbuilder/$i" ]; then
				die "Unable to find pbuilder config for target: $i"
			else
				# Check if target not updated for 7 days and update it
				if [ `find "/var/cache/pbuilder/base-${i}.tgz" -type f -mtime -7 | wc -l` = 0 ]; then
					echo "Target $i not updated last 7 days - updating it"
					sudo pbuilder --update --override-config --configfile "/etc/pbuilder/$i" || echo "Failed to update target: $i"
				fi
			fi
		done
	fi

	mkdir -p "$BUILD_OUTPUT"
	if [ ! -d "$BUILD_OUTPUT" ]; then
		die "Unable to create output directory: $BUILD_OUTPUT"
	fi
}

build_single_target() {
	local TARGET
	TARGET="$1"
	find /var/cache/pbuilder/result-$TARGET/ -type f -delete 2>/dev/null || die "Unable to cleanup pbuilder results directory: /var/cache/pbuilder/result-$TARGET"
	sudo pbuilder --build --configfile "/etc/pbuilder/$TARGET" "$BUILD_SRC"
	if [ $? != 0 ]; then
		warn "Failed to build `basename $BUILD_SRC` for target $TARGET"
        UNCLEAN_BUILD=1
	else
		DIST=`echo $i | perl -pi -e 's#-(i386|amd64)$##'`
		mkdir -p "$BUILD_OUTPUT/$DIST/$BUILD_REPO_PATH"
		if [ ! -d "$BUILD_OUTPUT/$DIST/$BUILD_REPO_PATH" ]; then
			die "Unable to create output directory: $BUILD_OUTPUT/$DIST/$BUILD_REPO_PATH"
		fi
		find /var/cache/pbuilder/result-$TARGET/ -type f ! -name '*.changes' -print0 | xargs -r0 mv -f -t "$BUILD_OUTPUT/$DIST/$BUILD_REPO_PATH"
		find /var/cache/pbuilder/result-$TARGET/ -type f -delete 2>/dev/null || die "Unable to cleanup pbuilder results directory: /var/cache/pbuilder/result-$TARGET"
	fi
}

build_all_targets() {
	for i in $SUPPORTED_TARGETS
	do
		build_single_target "$i"
	done
}

parse_cmdline "$@"
do_all_preparations

if [ "$BUILD_TARGET" = "all" ]; then
	build_all_targets
else
	for i in $BUILD_TARGET
	do
		build_single_target "$i"
	done
fi

if [ "$UNCLEAN_BUILD" -eq 1 ]; then
    warn "One or more targets were not built"
    exit 2
fi
