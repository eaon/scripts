#/bin/bash
# --------------------------------------------------------------------
# letsencrypt.sh
# --------------
# Create certificate signing requests and sign them to Let's Encrypt
#
# I don't like storing the user keys on my server so I use ssh-fs
# for the challenge.
#
# Author: Michael Zeltner <m@niij.org>
#         rsa8192/5DE83E90EFFCDDF9
# License: Public Domain
# Date: 05 Dec 2015
# Version: 0.1
# --------------------------------------------------------------------

BN=$(basename $0)

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	echo "$BN -- Create certificate signing requests and sign them to Let's Encrypt"
	echo
	echo Help:
	echo "$ $BN DOMAIN[:DOMAIN:DOMAIN] CERTFOLDER CHALLENGEFOLDER [USERKEY]"
	echo
	echo Default USERKEY: \~/.local/share/letsencrypt-user.key
	echo
	exit 0
fi

DOMAINS="$(tr ':' '\n' <<<$1)"
SAN="$(sed -e 's!:!,DNS:!g' <<<$1)"
CN=$(head -n1 <<<"$DOMAINS")
CF=$(realpath $2)
FN=$(echo $CF/$CN-$(date +%Y%m%d))
if [ "$4" = "" ]; then
	USERKEY="$HOME/.local/share/letsencrypt-user.key"
else
	USERKEY=$4
fi

if [ ! -e $USERKEY ]; then
	echo User key not found.
	exit 1
fi

exec 3<<<"$(cat $(find /etc/ -name openssl.cnf 2>/dev/null | head -n1))$(printf \\n[SAN]\\nsubjectAltName=DNS:$SAN)"

openssl req -new -nodes -sha512 -newkey rsa:4096 -keyout $FN.key -subj "/CN=$CN" -out $FN.csr -reqexts SAN -config /proc/$$/fd/3 -out $FN.csr

if [ $? -eq 0 ]; then
	python3 $(dirname $(realpath $0))/acme_tiny.py --account-key $USERKEY --csr $FN.csr --acme-dir $3 > $FN.crt
	if [ $? -ne 0 ]; then
		echo Failed to get them signed. Moving certs out of the way.
		FT="failed-$(date +%s)"
		for f in $FN*; do
			! grep -q failed <<<"$f" && mv $f $f-$FT
		done
		exit 1
	fi
fi
