#!/bin/bash
# --------------------------------------------------------------------
# GenderHackBot.sh
# ----------------
# A script to mirror hackerspaces.org on hackspaces.org, trying to
# get rid of the gender-connotation in languages in which "hacker" is
# a male noun. It transforms every mention of hackerspace to
# hackspaces.
#
# Author: Michael Zeltner <m@niij.org>
#         4096R/6CAC71020AF5D60D
# License: Public Domain
# Date: 20 Nov 2013
# Version: 0.2
# --------------------------------------------------------------------

if [ "$SCRIPT_NAME" = "" ]; then
    echo This script is meant to be executed as CGI script by an http server.
    echo
    echo Here is how to do that with Apache:
    echo
    echo 'RewriteEngine on'
    echo '# A file you should probably create'
    echo 'RewriteRule ^/robots.txt$ /robots.txt [L]'
    echo 'RewriteRule ^/$ /GenderHackBot.sh'
    echo 'RewriteRule ^/(.*)$ /GenderHackBot.sh/$1'
    echo
    echo '<Directory' $(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)'>'
    echo '    AddHandler cgi-script sh'
    echo '    Options ExecCGI'
    echo '</Directory>'
    echo
    echo It does not yet support multipart/form-data properly ...
    exit 1
fi

AGENT="GenderHackBot 23.42B/6 -- http://hackspaces.org/ -- $HTTP_USER_AGENT"
REQUEST_URI=$(echo $REQUEST_URI|/usr/bin/perl -pe 's/(hack)(space)/$1er$2/ig; s/(hack)([ _])(space)/$1er$2$3/ig; s,HackerspaceWiki:About,HackspaceWiki:About,g;')
DATA=""
if [ "$REQUEST_METHOD" == "POST" ]; then
	DATA=--data
fi
TYPE=""
if [ -n "$CONTENT_TYPE" ]; then
	TYPE=$(echo Content-type: $CONTENT_TYPE)
fi
# Respond with exactly the way that the other host does
curl -s -i "http://hackerspaces.org$REQUEST_URI" -A "$AGENT" -b "$HTTP_COOKIE" $DATA "$(cat /dev/stdin)" -H "$TYPE"|/usr/bin/perl -pe 's,HTTP/1.1,Status:,gi; s,Transfer-Encoding: chunked\r\n,,gi; s/Content-Length: [0-9]*\r\n//ig; s,http://hackerspaces.org/images/3/35/WikiLogo.png,http://hackerequality.org/files/2012/07/HackspaceWikiLogo.png,g; s/(hack)er(space)/$1$2/ig; s{https://(hackspaces)}{http://$1}ig; s/(hack)er([ _])(space)/$1$2$3/ig;'
