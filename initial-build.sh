#!/bin/bash

groupadd -g 5000 buildbot
useradd -u 5000 -g 5000 -d /home/buildbot -s /bin/bash buildbot
su - buildbot -c "/home/buildbot/build-mc-from-git.sh $1 $2"
exit $?
