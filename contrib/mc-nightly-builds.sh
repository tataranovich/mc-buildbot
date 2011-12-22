#!/bin/bash

echo "Started at `date -R`"

[ -x ~/bin/prepare-environment.sh ] && ~/bin/prepare-environment.sh

# Try to build with buildbot
sudo -u buildbot /home/buildbot/buildbot.sh --nightly >$HOME/tmp/nightly-builds.log 2>&1

case $? in
	0)
		echo "Build completed without error, starting repository update"
		break
		;;
	*)
		[ -f $HOME/tmp/nightly-builds.log ] && grep ^BUILDBOT $HOME/tmp/nightly-builds.log
		echo "Error while building project, skipping repo update"
		exit 1
		;;
esac

[ -d /home/buildbot/distribution ] && rsync -a /home/buildbot/distribution/ $HOME/my-local-repo/
$HOME/bin/local-repo-update >$HOME/tmp/nightly-repo-update.log 2>&1

if [ $? != 0 ]; then
	[ -f $HOME/tmp/nightly-repo-update.log ] && cat $HOME/tmp/nightly-repo-update.log
	exit 1
fi

echo "Successfully ended at `date -R`"
exit 0
