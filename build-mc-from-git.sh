#!/bin/bash
set -e

export DEBCHANGE_TZ="Europe/Minsk"
export DEBEMAIL="tataranovich@gmail.com"
export DEBFULLNAME="Andrey Tataranovich"

MC_GIT_REMOTE="git://midnight-commander.org/git/mc.git"
MC_DEBIAN_VCS="http://mc-buildbot.googlecode.com/hg"
MC_BUILD_PREFIX="/home/buildbot"
MC_GIT_LOCAL=${MC_BUILD_PREFIX}/mc-git
MC_TMP=${MC_BUILD_PREFIX}/mc-tmp
MC_BINARY=${MC_BUILD_PREFIX}/mc-build
MC_CONTRIB=${MC_BUILD_PREFIX}/mc-debian
MC_BUILD_TYPE="$1"

echo "BUILDBOT: -> Started build process at: `date -R`"

mkdir -p ${MC_BINARY}
[ ! -d ${MC_BUILD_PREFIX}/.series ] && mkdir -p ${MC_BUILD_PREFIX}/.series

# Update local debian part
if [ ! -d ${MC_CONTRIB} ]; then
	hg clone ${MC_DEBIAN_VCS} ${MC_CONTRIB}
else
	cd ${MC_CONTRIB}
	hg pull
	hg up -C default
fi

# Update local GIT repo if build type is nightly
if [ "${MC_BUILD_TYPE}" == "--nightly" ]; then
	if [ ! -d ${MC_GIT_LOCAL} ]; then
		git clone ${MC_GIT_REMOTE} ${MC_GIT_LOCAL}
	fi
	cd ${MC_GIT_LOCAL}
	git fetch
	git reset --hard origin/master
fi

# Check if build type is release and source distribution exists
if [ "${MC_BUILD_TYPE}" == "--release" -a -f "$2" ]; then
	MC_VERSION=`ls -1 "$2" | sed -e 's#^.*mc[-_]##' -e 's#\.orig\.tar\..*$##'`
	mv "$2" ${MC_BINARY}
fi

if [ -r ${MC_BUILD_PREFIX}/.series/nightly -a "${MC_BUILD_TYPE}" == "--nightly" ]; then
	LAST_GIT_COMMIT=`git log -n 1 | grep ^commit | head -n 1 | awk '{print $2}'`
	grep -q "^$LAST_GIT_COMMIT" ${MC_BUILD_PREFIX}/.series/nightly && {
		echo "BUILDBOT: Nightly build for commit $LAST_GIT_COMMIT already done."
		echo "BUILDBOT: Remove ${MC_BUILD_PREFIX}/.series/nightly if you want to force build"
		exit 1
	}
fi

echo "BUILDBOT: Checking if current source builds from scratch"

[ -d ${MC_TMP} ] && rm -fr ${MC_TMP}
if [ "${MC_BUILD_TYPE}" == "--nightly" ]; then
	cd ${MC_GIT_LOCAL}
	cp -r ${MC_GIT_LOCAL} ${MC_TMP}
	cd ${MC_TMP}
elif [ "${MC_BUILD_TYPE}" == "--release" ]; then
	mkdir -p ${MC_TMP}/release
	cd ${MC_TMP}/release
	tar xf ${MC_BINARY}/mc_${MC_VERSION}.orig.tar.gz
	cd ${MC_TMP}/release/mc-${MC_VERSION}	
fi

[ -x ./autogen.sh ] && ./autogen.sh
./configure --prefix=/usr --sysconfdir=/etc --libexecdir=/usr/lib/mc

if [ "${MC_BUILD_TYPE}" == "--nightly" ]; then
	make dist
	MC_VERSION=`ls -1 mc-*.tar.gz | sed -e 's#^mc-##' -e 's#\.tar\.gz$##'`
	PKG_VERSION=`echo $MC_VERSION | perl -pi -e 's/^([\d\.]+).*$/\1/'`
	mv mc-*.tar.gz ${MC_BINARY}/mc_${MC_VERSION}.orig.tar.gz
fi

make
make install DESTDIR=${MC_TMP}/install
rm -fr ${MC_TMP}

echo "BUILDBOT: Trying to build Debian package"

cd ${MC_BINARY}
tar xf ${MC_BINARY}/mc_${MC_VERSION}.orig.tar.gz
cd mc-${MC_VERSION}
cp -a ${MC_CONTRIB}/contrib/debian .
if [ "${MC_BUILD_TYPE}" == "--release" -a -f ${MC_BUILD_PREFIX}/.series/${MC_VERSION}.changelog ]; then
	cp -f ${MC_BUILD_PREFIX}/.series/${MC_VERSION}.changelog debian/changelog
fi

if [ "${MC_BUILD_TYPE}" == "--release" ]; then
	if [ -r ${MC_BUILD_PREFIX}/.series/${MC_VERSION} ]; then
		REL=`cat ${MC_BUILD_PREFIX}/.series/${MC_VERSION}`
		let REL=$REL+1
	else
		REL=1
	fi
	dch -v 3:${MC_VERSION}-${REL} 'New upstream release.'
elif [ "${MC_BUILD_TYPE}" == "--nightly" ]; then
	cd ${MC_BINARY}
	rm -fr mc-${MC_VERSION}
	tar xf ${MC_BINARY}/mc_${MC_VERSION}.orig.tar.gz
	mv mc-${MC_VERSION} mc-${PKG_VERSION}~git`date +'%Y%m%d'`
	tar czf mc_${PKG_VERSION}~git`date +'%Y%m%d'`.orig.tar.gz mc-${PKG_VERSION}~git`date +'%Y%m%d'`
	cd mc-${PKG_VERSION}~git`date +'%Y%m%d'`
	cp -a ${MC_CONTRIB}/contrib/debian .
	if [ -r ${MC_BUILD_PREFIX}/.series/git`date +'%Y%m%d'` ]; then
		REL=`cat ${MC_BUILD_PREFIX}/.series/git`date +'%Y%m%d'``
		let REL=$REL+1
	else
		REL=1
	fi
	dch -v 4:${PKG_VERSION}~git`date +'%Y%m%d'`-${REL} 'GIT build.'
fi

dpkg-buildpackage -rfakeroot -us -uc

echo "BUILDBOT: Checking with Lintian"

lintian ../*.changes 2>&1 | tee ${MC_BUILD_PREFIX}/lintian.last

if [ "${MC_BUILD_TYPE}" == "--release" ]; then
	echo $REL > ${MC_BUILD_PREFIX}/.series/${MC_VERSION}
	cp -f ${MC_BINARY}/mc-${MC_VERSION}/debian/changelog ${MC_BUILD_PREFIX}/.series/${MC_VERSION}.changelog
fi

if [ "${MC_BUILD_TYPE}" == "--nightly" ]; then
	cd ${MC_GIT_LOCAL}
	echo $REL > ${MC_BUILD_PREFIX}/.series/git`date +'%Y%m%d'`
	git log -n 1 | grep ^commit | head -n 1 | awk '{print $2}' > ${MC_BUILD_PREFIX}/.series/nightly
fi

echo "BUILDBOT: -> Ended build process at: `date -R`"
