#!/bin/sh
#A2subdirA.sh
#param $1: subdir name
#stdin: A (original path)
#stdout: B (new path in subdir)

#comments: 
#if no $1 is received A2subdirA.sh is a passthru
#if subdir doesn´t exist, it is created

while read line; do

if [ "$#" -eq 0 ]; then
    echo ${line}
else
    DIR=$(dirname ${line})
    NAME=$(basename ${line})
    SUBDIR="$DIR"/"$1"
    NEWLINE="$SUBDIR"/"$NAME"

    [ ! -d "$SUBDIR" ] && mkdir "$SUBDIR"

    mv ${line} "$NEWLINE"

    echo "$NEWLINE"
fi
done
exit 0