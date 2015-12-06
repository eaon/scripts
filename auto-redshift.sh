#!/bin/bash
# --------------------------------------------------------------------
# auto-redshift.sh
# ----------------
# autostart script for redshift as long as gnome-clock isn't
# available as location provider
#
# Author: Michael Zeltner <m@niij.org>
#         rsa8192/5DE83E90EFFCDDF9
# License: Public Domain
# Date: 03 Dec 2015
# Version: 0.1
# --------------------------------------------------------------------
choice() {
    echo "${@: $4:1}" >> ~/.config/redshift.conf
}

ARG=$(sed  -e "s,\(EST\|EDT\),1," -e "s,\(CEST\|CET\),2," -e "s,\(PST\|PDT\),3," <<<"$(date +%Z)")
 
if [[ $ARG != [1-3] ]]; then
    notify-send "Redshift" "I don't know where you are! You need to manually change the configuration!"
    exit 1
fi

echo "$(head -n -3 ~/.config/redshift.conf)" > ~/.config/redshift.conf
choice ';NYC'        ';VIE'       ';SFO'         $ARG 
choice 'lat=40.67'   'lat=48.15'  'lat=37.78'    $ARG
choice 'lon=-73.94'  'lon=16.22'  'lon=-122.41'  $ARG
