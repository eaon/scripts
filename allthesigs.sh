#!/bin/bash
# --------------------------------------------------------------------
# allthesigs.sh
# -------------
# Imports all files ending in pk.asc to gpg2, verifies all files
# ending in fp.asc for a good signature, and in case of success
# offers signing (or lsigning) the respective keys, followed by an
# export with the signatures (or lsignatures)
#
# Author: Michael Zeltner <m@niij.org>
#         4096R/6CAC71020AF5D60D
# License: Public Domain
# Date: 2 Feb 2014
# Version: 0.2.5
# --------------------------------------------------------------------

BN=$(basename $0)

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	echo $BN -- helps with air gapped key signing
	echo
	echo This script expects to have a files in the current folder to be named
	echo like this:
	echo
	echo foo-pk.asc
	echo foo-fp.asc
	echo bar-pk.asc
	echo bar-lsign-fp.asc
	echo
	echo pk.asc files should be public keys you wish to sign, fp.asc files are
	echo required to have the format of:
	echo
	echo "$ gpg --fingerprint bob@foo.bar | gpg --clearsign"
	echo
	echo This script checks for both good signatures as well as well as the
	echo overlap of clearsigned fingerprints with the ones that were imported.
	echo It exports public signatures as well as local signatures which you
	echo 'need to import with "--import-options import-local-sigs"'
	echo
	echo Happy Social Graph Leaking!
	echo
	exit 0
fi


GPG_TTY=$(tty)
export GPG_TTY

gpg2 --import *pk.asc 1>/dev/null 2>&1

while read signedfp; do
	signedid=$(grep pub $signedfp | grep -oe '/[A-F0-9]*' | cut -c 2-)
	# Checking if our signature is fine
	gpg2 --verify $signedfp 2>&1 >/dev/null | grep Good
	# Checking if fingerprint is the same one as the one we have signed
	[ $? -eq 0 ] && grep -q "$(gpg --fingerprint $signedid | sed -e 's,\[,\\\[,g')" $signedfp
	if [ $? -eq 0 ]; then
		echo Attempting to sign $signedid
		if echo $signedfp | grep -q lsign; then
			gpg2 --lsign-key $signedid
			gpg2 --armor --export-option export-local-sigs --export $signedid > lsigned-$signedid.asc
		else
			gpg2 --sign-key $signedid
			gpg2 --armor --export $signedid > signed-$signedid.asc
		fi
	else
		echo "You don't get to sign $signedfp"
	fi
done <<<"$(ls -1 | grep fp)"
