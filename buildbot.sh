#!/bin/bash

BUILDBOT_RES=0

if [ -z "$1" ]; then
	echo "Usage: $0 <--release|--nightly> [release_distribution]"
	exit 1
fi

if [ "$1" == "--release" -a ! -f "$2" ]; then
	echo "You must specify release_distribution as argument to --release"
	echo "Example: $0 --release /tmp/mc-4.7.5.5.tar.bz2"
	exit 1
fi

# Cleanup build environment
find /var/cache/pbuilder/result-* -type f -delete
rm -fr /home/buildbot/mc-build

case "$1" in
	--nightly) sudo pbuilder --execute --configfile /etc/pbuilder/buildbot -- /home/buildbot/initial-build.sh --nightly;;
	--release) sudo pbuilder --execute --configfile /etc/pbuilder/buildbot -- /home/buildbot/initial-build.sh --release "$2";;
	*)
		echo "$0: Incorrect option supplied"
		exit 1
		;;
esac || {
	echo "BUILDBOT: Initial build failed!"
	rm -fr /home/buildbot/mc-build
	exit 1
}

echo "BUILDBOT: Skipping piuparts check"
#echo "BUILDBOT: Start checking with piuparts"
#sudo piuparts --basetgz /var/cache/pbuilder/base-squeeze-i386.tgz -d squeeze /home/buildbot/mc-build/mc_*.changes && {
#	echo "BUILDBOT: piuparts check sucessfull, starting target builds"
	case "$1" in
		--release)
			/home/buildbot/target-build.sh --target all --src /home/buildbot/mc-build/mc_*.dsc --repository main/m/mc --output /home/buildbot/distribution/pool
            BUILDBOT_RES=$?
			;;
		--nightly)
			/home/buildbot/target-build.sh --target all --src /home/buildbot/mc-build/mc_*.dsc --repository nightly/m/mc --output /home/buildbot/distribution/pool
            BUILDBOT_RES=$?
			;;
	esac
#} || echo "BUILDBOT: piuparts check failed. Skipping target builds"

echo "BUILDBOT: All finished"

# Fix permissions
if [ -d /home/buildbot/distribution ]; then
	find /home/buildbot/distribution -type d -print0 | xargs -r0 chmod 755
	find /home/buildbot/distribution -type f -print0 | xargs -r0 chmod 644
fi

rm -fr /home/buildbot/mc-build
exit $BUILDBOT_RES
