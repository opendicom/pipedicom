#!/bin/sh
# $1 MISMATCH_SERVICE path

find "$1" -depth 3 -type d ! -empty -mtime +300s -print0 | while read -d $'\0' STUDY
do
    SEND=$(echo "$STUDY" | sed -e 's/MISMATCH_SERVICE/SEND/')
    SENDDIR=$( dirname "$SEND" )
    if [ ! -d "$SENDDIR" ]; then
        mkdir -p "$SENDDIR"
    fi
    if [ -d "$SEND" ]; then
        cd "$STUDY"
        for SERIES in `ls`; do
            mv "$STUDY"'/'"$SERIES" "$SEND"
        done
        #rm -Rf "$STUDY"
    else
        mv "$STUDY" "$SEND"
    fi
done

