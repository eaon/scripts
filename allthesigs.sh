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
# Version: 0.2
# --------------------------------------------------------------------

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
