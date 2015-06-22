#!/usr/bin/env python3
# --------------------------------------------------------------------
# ffskeys.py
# ----------
# For Fucks Sake Keys!!!!!
# Fuck Fedora, Search Keys
#
# Search/receive OpenPGP keys on keyservers, and fuck Fedora's build
# system: https://bugzilla.redhat.com/show_bug.cgi?id=1224816
# Certificate Authority for mayfirst / people link:
# https://support.mayfirst.org/wiki/faq/security/mfpl-certificate-authority
#
# Barebones implementation of machine readable keyserver indexes. Does
# not do any fingerprint validation whatsoever, blindly trusts
# keyserver. Might change in the future.
#
# Author: Michael Zeltner <m@niij.org>
#         8192R/5DE83E90EFFCDDF9
# License: Public Domain
# Date: 22 Jun 2015
# Version: 0.1
# --------------------------------------------------------------------

import requests
import sys
import argparse
import time

def receive(keyid):
    keyid = "".join(keyid)
    r = requests.get("https://zimmermann.mayfirst.org/pks/lookup?op=get" \
                     "&search=0x%s" % keyid, verify=True)
    if "No keys found" in r.text:
        print("No keys found")
        sys.exit(1)
    open("%s.asc" % keyid,
         "w").write(r.text.split("<pre>")[1].split("</pre>")[0].strip())
    print("Wrote key to '%s.asc'" % keyid)

def search(term):
    r = requests.get("https://zimmermann.mayfirst.org/pks/lookup?op=vindex" \
                     "&search=%s&options=mr" % "%20".join(term), verify=True)
    def algName(no):
        if no == 1:
            return "RSA"
        elif no == 2:
            return "RSA (encrypt only)"
        elif no == 3:
            return "RSA (sign only)"
        elif no == 16:
            return "ElGamal"
        elif no == 17:
            return "DSA"
        elif no == 18:
            return "ECDH"
        elif no == 19:
            return "ECDSA"
    def enum(c):
        no = "(%s)" % c
        return no + " " * (8 - len(no))
    results = r.text.strip()
    pubkeys = results.split('pub:')[1:]
    c = 0
    fprs = []
    for key in pubkeys:
        lines = key.strip().split('\n')
        meta = lines[0].split(':')
        fpr = meta[0]
        fprs.append(fpr)
        alg = algName(int(meta[1]))
        bit = meta[2]
        crt = time.strftime('%Y-%m-%d', time.localtime(int(meta[3])))
        try:
            exp = time.localtime(int(meta[4]))
            now = int(time.strftime("%s", time.localtime()))
            thn = int(time.strftime("%s", exp))
            old = now > thn
            exp = time.strftime(", expires: %Y-%m-%d" \
                                + " (expired)" if old else "", exp)
        except:
            exp = ""
        rev = " (revoked)" if meta[5] == "r" else ""
        c += 1
        u = 0
        for line in lines[1:]:
            if "uid" in line:
                print("%s%s" % (" " * 8 if u > 0 else enum(c),
                                line.split(':')[1]))
                u = 1
        print(" " * 10 + "%s bit %s key %s, created %s%s%s" % (bit, alg,
                                                               fpr[-16:], crt,
                                                               exp, rev))
    n = input("%s Keys for '%s'. Enter number to write to file, or (q)uit > " \
              % (c, " ".join(term)))
    try:
        n = int(n) - 1
    except:
        pass
    if isinstance(n, int):
        receive(fprs[n])

if __name__ == "__main__":
    parser = argparse.ArgumentParser('parent', add_help=False)
    parser.add_argument('--version', action='version',
                            version='%(prog)s 0.1')
    parser = argparse.ArgumentParser(parents=[parser])
    sub_p = parser.add_subparsers(help='actions')
    p_s = sub_p.add_parser('s', help='search for keys')
    p_s.add_argument("term", nargs='*')
    p_r = sub_p.add_parser('r', help='receive keys (write to file)')
    p_r.add_argument("keyid", nargs='?')
    args = parser.parse_args()
    if 'term' in args:
        search(args.term)
    elif 'keyid' in args:
        receive(args.keyid)
