#!/bin/sh
# $1 directory LOG
#                 /branch/device/euid/suid.sh
#                 /branch/device/euid/date/suid.sh

# uses logs only to determine if coerced files can be deleted
# this is a process separate from sending so that deleting may be deferred in tim

#color codes
# 1 orange
# 2 red        remote error (execute log)
# 3 yellow
# 4 blue       removed local
# 5 purple
# 6 green      not found local
# 7 grey       not a opendicom signed log file

DONEDIRNAME=$(date '+%Y%m%d%H%M%S')

#SUIDLOGSHPATH is an ABSOLUTE path (not a relative one)
find "$1" -depth 4 -type f -name '*.sh' -Btime +1d -print0 | while read -d $'\0' SUIDLOGSHPATH
do
    printf "$SUIDLOGSHPATH"' : '
    LOG=$(cat "$SUIDLOGSHPATH")
    
    if [[ $LOG != *"#opendicom.storedicom"* ]]; then
        echo 'NOT A SIGNED LOG FILE'
        osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$SUIDLOGSHPATH\" to 7"
    else
        if [[ $LOG == *FAILED* ]]; then
            echo $( sh "$SUIDLOGSHPATH" )
            osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$SUIDLOGSHPATH\" to 2"
        elif [[ $LOG == *REFERENCED* ]]; then

            SERIESDIR=$( sh "$SUIDLOGSHPATH" )

            if  [[ $SERIESDIR != '' ]]; then
                if [ -d "$SERIESDIR" ];then
                    rm -Rf "$SERIESDIR"
                    #blue
                    osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$SUIDLOGSHPATH\" to 4"
                else #[! -d "$SERIESDIR" ]
                    #green
                    osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$SUIDLOGSHPATH\" to 6"
                fi
            fi
        else
            osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$SUIDLOGSHPATH\" to 7"
        fi
    fi

#DONE iN aaaammddhhmmss/
    DONEDIRPATH="$(dirname "$SUIDLOGSHPATH")"'/'"$DONEDIRNAME"
    if [ ! -d "$DONEDIRPATH" ]; then
        mkdir -p "$DONEDIRPATH"
    fi
    mv "$SUIDLOGSHPATH" "$DONEDIRPATH"

done
