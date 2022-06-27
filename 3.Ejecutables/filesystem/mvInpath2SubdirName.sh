#!/bin/sh
#mvInpath2SubdirName.sh
#param $1: subdir name
#stdin: inpath
#stdout: newpath in subdir

#if subdir doesn´t exist, it is created

while read line; do

if [ "$#" -eq 0 ]; then
    #if no $1 is received subdir.sh is a passthru
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
