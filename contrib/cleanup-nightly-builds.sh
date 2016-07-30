#!/bin/bash

DEB_POOL_DIR=/home/andrey/my-local-repo/pool
DEB_NIGHTLY_LAST=""
DEB_NIGHTLY_COUNT=0

if [ ! -d ${DEB_POOL_DIR} ]; then
	echo "Unable to find POOL dir: ${DEB_POOL_DIR}" >&2
	exit 1
fi

for i in `seq 0 365`
do
	GIT_STAMP=`date -d "$i days ago" +'%Y%m%d'`
	if [ `find ${DEB_POOL_DIR}/sid/nightly/m/mc -type f -name "*~git${GIT_STAMP}*.dsc" | wc -l` == 1 ]; then
		let DEB_NIGHTLY_COUNT=${DEB_NIGHTLY_COUNT}+1
		if [ ${DEB_NIGHTLY_COUNT} -ge 7 ]; then
			DEB_NIGHTLY_LAST=${GIT_STAMP}
			break
		fi
	fi
done

if [ ${DEB_NIGHTLY_COUNT} -lt 7 ]; then
	DEB_NIGHTLY_LAST=${GIT_STAMP}
fi

echo "Will preserve ${DEB_NIGHTLY_COUNT} nightly builds, last preserved build: ${DEB_NIGHTLY_LAST}"

for i in `seq 365 -1 0`
do
	GIT_STAMP=`date -d "$i days ago" +'%Y%m%d'`
	if [ "${GIT_STAMP}" == "${DEB_NIGHTLY_LAST}" ]; then
		break
	fi
	rm -fv ${DEB_POOL_DIR}/*/nightly/m/mc/*~git${GIT_STAMP}*
done
