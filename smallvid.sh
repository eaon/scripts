#!/bin/bash
# --------------------------------------------------------------------
# smallvid.sh
# -----------
# Compress videos to acceptable size while leaving resolution etc.
# untouched, also making them streamable. Requires avconv and
# qt-faststart
# 
# Because I was too lazy to find these over and over again
#
# Author: Michael Zeltner <m@niij.org>
#         4096R/6CAC71020AF5D60D
# License: Public Domain
# Date: 21 Nov 2013
# Version: 0.2
# --------------------------------------------------------------------

BITRATE="2M"
if [ -n "$2" ]; then
    BITRATE="$2"
fi
echo $3
TMPFILE=".tmp.$1.mp4"
OUTFILE="$1.mp4"
OPTIONS="-vcodec libx264 -b:v $BITRATE -flags +loop+mv4 -cmp 256 \
         -partitions +parti4x4+parti8x8+partp4x4+partp8x8+partb8x8 \
         -me_method hex -subq 7 -trellis 1 -refs 5 -bf 3 \
         -flags2 +bpyramid+wpred+mixed_refs+dct8x8 -coder 1 -me_range 16 \
             -g 250 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -qmin 10\
         -qmax 51 -qdiff 4"
ffmpeg -y -i $1 -an -pass 1 -threads 2 $OPTIONS "$TMPFILE"
ffmpeg -y -i $1 -acodec aac -ar 44100 -pass 2 -threads 2 $OPTIONS -ab 128k "$TMPFILE"
qt-faststart "$TMPFILE" "$OUTFILE"
rm "$TMPFILE" av2pass-0.log av2pass-0.log.mbtree
