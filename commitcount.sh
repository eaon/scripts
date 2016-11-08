#!/bin/bash
# --------------------------------------------------------------------
# commitcount
# -----------
# For scripts that are to be made public, or not
#
# Author: Michael Zeltner <m@niij.org>
#         rsa8192/5DE83E90EFFCDDF9
# License: Public Domain
# Date: 07 Nov 2016
# Version: 0.1
# --------------------------------------------------------------------

BN=$(basename $0)

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	echo "$BN -- very inefficient counting of the last 30 days worth of commits"
    echo 
	echo Help:
	echo "$ $BN BASEFOLDER [AUTHOR-EMAIL]"
    echo
    echo Format:
    echo YYYY-MM-DD:COMMITS:REPO
	echo
	exit 0
fi


if [ "$1" = "" ]; then
    echo Please give me a base folder.
    exit 1
fi

BASEFOLDER="$(cd $1; pwd)"

if [ "$2" = "" ]; then
	AUTHOR="--author=$email"
else
	AUTHOR=$2
fi

function counthere {
	for head in $(git show-ref --heads -s); do
		for day in $(seq 0 30); do
			daydate=$(date -d "$day days ago" +%Y-%m-%d)
			count=$(git rev-list --count $AUTHOR --since="$daydate 00:00:00" --before="$daydate 23:59:59" $head 2>/dev/null)
			[ $? -ne 0 ] && echo $(pwd) would not run git rev-list && exit 1
			if [ $count -gt 0 ]; then
				echo $daydate:$count:$(pwd)
			fi
		done
	done
}

for repo in $(find $BASEFOLDER -name "*.git" -type d | sed -e 's, ,​,g'); do
	cd "$(sed -e 's,​, ,g' <<<$repo)"
	counthere
	cd "$BASEFOLDER"
done
