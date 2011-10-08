#!/bin/bash

TARGETS="lenny-i386 lenny-amd64 squeeze-i386 squeeze-amd64 maverick-i386 maverick-amd64 natty-i386 natty-amd64"

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
#	--check) sudo pbuilder --execute --configfile /etc/pbuilder/buildbot -- /home/buildbot/initial-build.sh --check;;
	*) exit 1;;
esac || {
	echo "BUILDBOT: Initial build failed!"
	rm -fr /home/buildbot/mc-build
	exit 1
}

# Check build without targets
#rm -fr /home/buildbot/mc-build
#exit 0

echo "BUILDBOT: Start checking with piuparts"
sudo piuparts --basetgz /var/cache/pbuilder/base-squeeze-i386.tgz -d squeeze /home/buildbot/mc-build/mc_*.changes && {
	echo "BUILDBOT: piuparts check sucessfull, starting target builds"
	for i in $TARGETS
	do
		echo "BUILDBOT: -> build target $i"
		sudo pbuilder --build --configfile /etc/pbuilder/$i /home/buildbot/mc-build/mc_*.dsc && {
			echo "BUILDBOT: -> updating $i distribution"
			DIST=`echo $i | perl -pi -e 's#-(i386|amd64)##'`
			case "$1" in
				--nightly) 	mkdir -p /home/buildbot/distribution/pool/$DIST/nightly/m/mc
							mv -f /var/cache/pbuilder/result-$i/*.deb /home/buildbot/distribution/pool/$DIST/nightly/m/mc
							echo $i | grep -q 'i386$' && \
							mv -f /var/cache/pbuilder/result-$i/* /home/buildbot/distribution/pool/$DIST/nightly/m/mc
							;;
				--release)	mkdir -p /home/buildbot/distribution/pool/$DIST/main/m/mc
							mv -f /var/cache/pbuilder/result-$i/*.deb /home/buildbot/distribution/pool/$DIST/main/m/mc
							echo $i | grep -q 'i386$' && \
							mv -f /var/cache/pbuilder/result-$i/* /home/buildbot/distribution/pool/$DIST/main/m/mc
			esac
			rm -f /var/cache/pbuilder/result-$i/mc_*
		}
	done
} || echo "BUILDBOT: piuparts check failed. Skipping target builds"

echo "BUILDBOT: All finished"

# Fixxing rights
if [ -d /home/buildbot/distribution ]; then
	find /home/buildbot/distribution -type d -print0 | xargs -r0 chmod 755
	find /home/buildbot/distribution -type f -print0 | xargs -r0 chmod 644
fi

rm -fr /home/buildbot/mc-build
exit 0
