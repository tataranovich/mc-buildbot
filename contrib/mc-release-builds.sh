#!/bin/bash

echo "Started at `date -R`"

[ -x ~/bin/prepare-environment.sh ] && ~/bin/prepare-environment.sh

if [ "$1" != "--force" ]; then
	uscan --destdir /home/buildbot/tmp/uscan --download --repack --rename $HOME/debian-packages/mc || {
		echo
		echo "Now new release found"
		echo
		echo "Successfully ended at `date -R`"
		exit 0
	}
elif [ "$1" == "--force" ]; then
	if [ ! -z "$2" ]; then
		echo "Trying to download explicit version: $2"
		uscan --destdir /home/buildbot/tmp/uscan --force-download --repack --download-version "$2" --rename $HOME/debian-packages/mc || exit 1
	else
		uscan --destdir /home/buildbot/tmp/uscan --force-download --repack --rename $HOME/debian-packages/mc || exit 1
	fi
fi

MC_SOURCE=`find /home/buildbot/tmp/uscan -type f -name 'mc*tar.*'`
# Try to build with buildbot
sudo -u buildbot /home/buildbot/buildbot.sh --release "$MC_SOURCE" >$HOME/tmp/release-builds.log 2>&1

if [ $? != 0 ]; then
	[ -f $HOME/tmp/release-builds.log ] && grep ^BUILDBOT $HOME/tmp/release-builds.log
	echo "Error while building project, skipping repo update"
	rm -f /home/buildbot/tmp/uscan/mc*tar.*
	exit 1
fi
rm -f /home/buildbot/tmp/uscan/mc*tar.*

if [ "$1" != "--force" -a -f /home/buildbot/mc-binary/mc-*/debian/changelog ]; then
	echo "Updating changelog for uscan"
	cat /home/buildbot/mc-binary/mc-*/debian/changelog > $HOME/debian-packages/mc/debian/changelog
fi

[ -d /home/buildbot/distribution ] && rsync -a /home/buildbot/distribution/ $HOME/my-local-repo/
$HOME/bin/local-repo-update >$HOME/tmp/release-repo-update.log 2>&1

if [ $? != 0 ]; then
	[ -f $HOME/tmp/release-repo-update.log ] && cat $HOME/tmp/release-repo-update.log
	exit 1
fi

echo "Successfully ended at `date -R`"
exit 0
