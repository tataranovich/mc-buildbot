#!/bin/bash
#
# Example: buildbot-build-target.sh --build release --target lenny-amd64 --src ~/tmp/test.dsc
#

TARGETS="lenny-i386 lenny-amd64 squeeze-i386 squeeze-amd64 wheezy-i386 wheezy-amd64 sid-i386 sid-amd64 lucid-i386 lucid-amd64 maverick-i386 maverick-amd64 natty-i386 natty-amd64 oneiric-i386 oneiric-amd64 precise-i386 precise-amd64"

die() {
	if [ ! -z "$1" ]; then
		echo "$1"
	fi
	exit 1
}

usage() {
	echo "Example: buildbot-build-target.sh --build release --target lenny-amd64 --src ~/tmp/test.dsc"
	exit 0
}

parse_cmdline() {
	if [ $# -eq 0 ]; then
		usage
	fi
	set -- `getopt -u --longoptions="build: target: src: move-results:" -- -- "$@"` || usage
	while [ $# -gt 0 ]
	do
		case "$1" in
			--build) BUILD_TYPE="$2"; shift;;
			--target) BUILD_TARGET="$2"; shift;;
			--src) BUILD_SRC="$2"; shift;;
			--) shift;break;;
			*) break;
		esac
		shift
	done
}

sanitize_supplied_options() {
	local _TARGET_VALID
	_TARGET_VALID=0
	[ ! -z "$BUILD_TYPE" ] || die "You must specify build type"
	case $BUILD_TYPE in
		release);;
		nightly);;
		*) die "Build type must be release or nightly"
	esac

	[ ! -z "$BUILD_TARGET" ] || die "You must specify build target"
	if [ "$BUILD_TARGET" != "all" ]; then
		for i in $TARGETS
		do
			if [ "$i" == "$BUILD_TARGET" ]; then
				_TARGET_VALID=1
				break
			fi
		done
	else
		_TARGET_VALID=1
	fi
	if [ ! $_TARGET_VALID -eq 1 ]; then
		die "Specified target not included in TARGETS list"
	fi
	
	if [ "$BUILD_TARGET" != "all" ]; then
		if [ ! -f "/etc/pbuilder/$BUILD_TARGET" ]; then
			die "Unable to find pbuilder config: /etc/pbuilder/$BUILD_TARGET"
		fi
	fi

	if [ ! -f "$BUILD_SRC" ]; then
		die "Unable to find source: $BUILD_SRC"
	fi
}

build_single_target() {
	local TARGET
	TARGET="$1"
	sudo pbuilder --build --configfile /etc/pbuilder/$TARGET $BUILD_SRC && {
		DIST=`echo $i | perl -pi -e 's#-(i386|amd64)##'`
		case "$BUILD_TYPE" in
			release)
				mkdir -p /home/buildbot/distribution/pool/$DIST/main/m/mc
				mv -f /var/cache/pbuilder/result-$TARGET/*.deb /home/buildbot/distribution/pool/$DIST/main/m/mc
				echo $TARGET | grep -q 'i386$' && \
				mv -f /var/cache/pbuilder/result-$TARGET/* /home/buildbot/distribution/pool/$DIST/main/m/mc
				rm -f /home/buildbot/distribution/pool/$DIST/main/m/mc/*.changes
				;;
			nightly)
				mkdir -p /home/buildbot/distribution/pool/$DIST/nightly/m/mc
				mv -f /var/cache/pbuilder/result-$TARGET/*.deb /home/buildbot/distribution/pool/$DIST/nightly/m/mc
				echo $TARGET | grep -q 'i386$' && \
				mv -f /var/cache/pbuilder/result-$TARGET/* /home/buildbot/distribution/pool/$DIST/nightly/m/mc
				rm -f /home/buildbot/distribution/pool/$DIST/main/m/mc/*.changes
				;;
		esac
		rm -f /var/cache/pbuilder/result-$TARGET/mc_*
	}
}

build_all_targets() {
	for i in $TARGETS
	do
		build_single_target $i
	done
}

parse_cmdline "$@"
sanitize_supplied_options

case $BUILD_TARGET in
	all) build_all_targets;;
	*) build_single_target $BUILD_TARGET
esac

exit 0
