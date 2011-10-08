#!/bin/bash

echo "Started at `date -R`"

[ -x ~/bin/prepare-environment.sh ] && ~/bin/prepare-environment.sh

if [ -r /home/buildbot/.series/nightly -a -d /home/buildbot/mc-git ]; then
	pushd /home/buildbot/mc-git >/dev/null
	LAST_GIT_COMMIT=`git log -n 1 | grep ^commit | head -n 1 | awk '{print $2}'`
	grep -q "^$LAST_GIT_COMMIT" /home/buildbot/.series/nightly && {
		echo
		echo "Nightly build for commit $LAST_GIT_COMMIT already done."
		echo "Remove /home/buildbot/.series/nightly if you want to force build"
		echo
		echo "Successfully ended at `date -R`"
		exit 0
	}
	popd
fi

# Try to build with buildbot
sudo -u buildbot /home/buildbot/buildbot.sh --nightly >$HOME/tmp/nightly-builds.log 2>&1

if [ $? != 0 ]; then
	[ -f $HOME/tmp/nightly-builds.log ] && grep ^BUILDBOT $HOME/tmp/nightly-builds.log
	echo "Error while building project, skipping repo update"
	exit 1
fi

[ -d /home/buildbot/distribution ] && rsync -a /home/buildbot/distribution/ $HOME/my-local-repo/
$HOME/bin/local-repo-update >$HOME/tmp/nightly-repo-update.log 2>&1

if [ $? != 0 ]; then
	[ -f $HOME/tmp/nightly-repo-update.log ] && cat $HOME/tmp/nightly-repo-update.log
	exit 1
fi

echo "Successfully ended at `date -R`"
exit 0
