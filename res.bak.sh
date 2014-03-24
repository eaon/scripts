#!/bin/bash
# --------------------------------------------------------------------
# res.bak.sh
# ----------
# Periodically downloads changes of a given http(s) resource, with
# support for git checkins
#
# Author: Michael Zeltner <m@niij.org>
#         4096R/6CAC71020AF5D60D
# License: Public Domain
# Date: 20 Nov 2013
# Version: 0.6
# --------------------------------------------------------------------

GIT=0
GITAUTHOR="res.bak.sh <res.bak.sh@transist.or.at>"
BN=$(basename $0)

help() {
    echo "$BN -- Periodically downloads changes of a http(s) resource (with curl)"
    echo
    echo Help:
    echo "$ $BN [-g|--git] 'https://...' file-suffix|git-filename seconds"
    echo "Default: 300 seconds (5 mins)"
    echo
    echo The git function assumes the current directory is a git repository,
    echo 'the $gitfilename has already been added to the repository'
    echo
    echo Examples:
    echo $ $BN 'https://pad.riseup.net/p/example/export/txt' txt 60
    echo $ $BN --git 'https://pad.riseup.net/p/example/export/txt' example.txt 60
    echo
    exit 1
}

if [[ "$1" = "-h" || "$1" = "--help" || "$1" = "" ]]; then
    help
fi

URL=$1
SUF=$2
if [ ! "$SUF" = "" ]; then
    SUF=".$SUF"
fi
SECS=$3

if [[ "$1" = "-g" || "$1" = "--git" ]]; then
    GIT=1
    URL=$2
    NAME=$3
    SECS=$4
fi

if [[ ! "$(echo $URL | grep -o '^http')" = "http" || ! "$(echo $URL | grep ' ')" = "" ]]; then
    echo "Wrong argument: $URL is not a http(s) url"
    echo
    help
fi

if [ "$SECS" =  "" ]; then
    SECS=$(expr 60 \* 5)
elif [[ $SECS == *[!0-9]* ]]; then
    echo Wrong argument: $SECS is not a number
    echo
    help
fi

get() {
    curl -s -o "$2" "$1" 2> /dev/null
    if [ $? -ne 0 ]; then
        echo "curl didn't exit properly, aborting."
        echo "Tried to run $ curl -s -o \"$2\" \"$1\""
        echo
        help
    fi
}

if [ $GIT -eq 0 ]; then
    OT=0
    while [ 1 == 1 ]; do
        NT=$(date +%s)
        if [ $OT -eq 0 ]; then
            get "$URL" "$NT$SUF"
            echo Saved initial content to "$NT$SUF"
            OT=$NT
            sleep $SECS
            continue
        fi
        OUT="$(get $URL '-')"
        diff - $OT$SUF<<<"$OUT" > /dev/null 2>&1
        if [ $? -gt 0 ]; then
            cat -<<<"$OUT" > "$NT$SUF"
            echo Saved new content to "$NT$SUF"
            OT=$NT
        else
            echo Contents unchanged
        fi
        sleep $SECS
    done
fi

if [ $GIT -eq 1 ]; then
    while [ 1 == 1 ]; do
        get "$URL" "$NAME"
        if [ $(git diff "$NAME" | wc -l) -gt 0 ]; then
            git commit --author="$GITAUTHOR" -m "Auto-committing new changes of $URL" "$NAME"
        else
            echo Contents unchanged
        fi
        sleep $SECS
    done
fi
