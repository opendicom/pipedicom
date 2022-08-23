#!/bin/sh
# $1 MISMATCH_SERVICE path

find "$1" -depth 3 -type d ! -empty -mtime +300s -print0 | while read -d $'\0' MISMATCHSTUDY
do
    SENDSTUDY=$(echo "$MISMATCHSTUDY" | sed -e 's/MISMATCH_SERVICE/SEND/')
    SENDDIR=$( dirname "$SENDSTUDY" )
    mkdir -p "$SENDDIR"
    if [ -d "$SENDSTUDY" ]; then
        cd "$MISMATCHSTUDY"
        for SERIES in `ls`; do
            mv "$MISMATCHSTUDY"'/'"$SERIES" "$SENDSTUDY"
        done
        #rm -Rf "$STUDY"
    else
        mv "$MISMATCHSTUDY" "$SENDSTUDY"
    fi
done

