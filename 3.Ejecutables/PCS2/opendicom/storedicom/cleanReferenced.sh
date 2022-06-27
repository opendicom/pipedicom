#!/bin/sh
# $1 directorio de log

#color codes
# 1 orange
# 2 red        error
# 3 yellow     recycled
# 4 blue
# 5 purple
# 6 green      found remote, removed local
# 7 grey       no list

DONEDIRNAME=$(date '+%Y%m%d%H%M%S')

#LINE is an ABSOLUTE path (not a relative one)

find "$1" -depth 3 -type f -name '*.sh' -Btime +1d -print0 | while read -d $'\0' LINE
do
    printf "$LINE"' : '
    LOG=$(cat "$LINE")
    if [[ $LOG == *#uy.asse.ridi.pcs.2.1.opendicom.storedicom.log* ]]; then

        LINENAME=$(basename  "$LINE")

        if [[ $LOG == *FAILED* ]]; then
            echo $( sh "$LINE" )
            
        elif [[ $LOG == *REFERENCED* ]]; then
        
            SRCBUCKET=$( sh "$LINE" )
            
            if  [[ $SRCBUCKET != '' ]]; then
                if [ -d "$SRCBUCKET" ];then
                    rm -Rf "$SRCBUCKET"
                    #blue
                    osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$LINE\" to 4"
                    LINEtxt=${LINE%.*}'.txt'
                    if [ -f "$LINEtxt" ]; then
                        osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$LINEtxt\" to 4"
                    fi
                else #[! -d "$SRCBUCKET" ]
                    #green
                    osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$LINE\" to 6"
                fi
            else #[[ $SRCBUCKET == '' ]]
                #grey
                osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$LINE\" to 7"
            fi
        else
            # other kind of response
            echo "$LINE"
            echo "$LOG"
            #grey
            osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$LINE\" to 7"
        fi
    else [[ $LOG != *#uy.asse.ridi.pcs.2.1.opendicom.storedicom.log* ]]
        echo 'NOT SIGNED LOG FILE: '"$LINE"
        echo "$LOG"
        #grey
        osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$LINE\" to 7"
    fi

#DONE iN aaaammddhhmmss/
    DONEDIRPATH="$(dirname "$LINE")"'/'"$DONEDIRNAME"
    if [ ! -d "$DONEDIRPATH" ]; then
        mkdir -p "$DONEDIRPATH"
    fi
    mv "$LINE" "$DONEDIRPATH"

done
