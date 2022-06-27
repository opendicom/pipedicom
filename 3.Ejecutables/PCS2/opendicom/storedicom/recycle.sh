#!/bin/sh
# args: filenames of failed files to be recicled, removed or need investigation

#color codes

# 6 green   OKLIST  found remote,           not found local
# 4 blue    RMLIST  found remote,           removed local
# 5 purple  MVLIST  not found remote,       recycled local
# 3 yellow  BRLIST  bad response remote,    found local
# 1 orange  ERLIST  bad answer from remote
# 2 red     NNLIST  found Neither remote    Nor local
# 7 grey    no list empty bucket

#params = list of parts

if [[ $SRCBUCKET == '' ]] || [[ $DSTBUCKET == '' ]] || [[ $LOGPATH == '' ]]; then
    echo SRCBUCKET, DSTBUCKET and LOGPATH required
else

    

    OKLIST=''
    NNLIST=''
    ERLIST=''

    RMLIST=''
    MVLIST=''
    BRLIST=''
    
    # loop iuid
    for LINE in "$@"; do
        QIDORESPONSE=$( curl -s -f 'https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE/instances?SOPInstanceUID='"$LINE" )
        
        FILENAME=$(find "$SRCBUCKET" -name "$LINE"'*')
        if [[ $FILENAME == '' ]]; then
# not found locally
            if [[ $QIDORESPONSE == "["* ]]; then
                echo 'OK '
                OKLIST="$OKLIST""$LINE"'\r\n'
            elif [[ $QIDORESPONSE == '' ]]; then
                echo 'NN '
                NNLIST="$NNLIST""$LINE"'\r\n'
            else
                echo '\r\nER '"$LINE"'\r\n'
                echo "$QIDORESPONSE"'\r\n'
                ERLIST="$ERLIST""$LINE"'\r\n'
            fi
        else
# found locally
            if [[ $QIDORESPONSE == "["* ]]; then # found by qido request
                echo 'RM '
                rm -f "$FILENAME"
                RMLIST="$RMLIST""$LINE"'\r\n'
            elif [[ $QIDORESPONSE == '' ]]; then
                # recycle in SEND directory
                echo 'MV '
                if [ ! -d "$DSTBUCKET" ]; then
                    mkdir -p "$DSTBUCKET"
                fi
                mv "$SRCBUCKET""$FILENAME" "$DSTBUCKET"
                MVLIST="$MVLIST""$LINE"'\r\n'
            else # response not json
                echo '\r\nBR '"$LINE"'\r\n'
                echo "$QIDORESPONSE"'\r\n'
                BRLIST="$BRLIST""$LINE"'\r\n'
            fi
        fi
    done

    echo hola

    if [[ "$OKLIST" != '' ]]; then
        echo '\r\nALREADY SENT, NO ACCION REQUIRED'
        echo "$OKLIST"
        #green
        osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$LOGPATH\" to 6"
    fi

    if [[ "$RMLIST" != '' ]]; then
        echo '\r\nALREADY SENT'
        echo 'REMOVED FROM PCS2 STOREDICOM STORAGE'
        echo "$RMLIST"
        #blue
        osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$LOGPATH\" to 4"
    fi

    if [[ "$MVLIST" != '' ]]; then
        echo '\r\nRECYCLED'
        echo "$MVLIST"
        #purple
        osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$LOGPATH\" to 5"
    fi


    if [[ "$BRLIST" != '' ]]; then
        echo '\r\nBAD RESPONSE, FOUND LOCAL'
        echo BRLIST
        #yellow
        osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$LOGPATH\" to 3"
    fi

    if [[ "$ERLIST" != '' ]]; then
        echo '\r\nBAD RESPONSE, NOT FOUND LOCAL'
        echo "$ERLIST"
        #orange
        osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$LOGPATH\" to 1"
    fi


    if [[ "$NNLIST" != '' ]]; then
        echo '\r\nNOT FOUND (NEITHER lOCAL, NOR REMOTE)'
        echo "$NNLIST"
        #red
        osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$LOGPATH\" to 2"
    fi


    if [[ "$MVLIST" == '' ]] && [[ "$BRLIST" == '' ]] && [[ "$ERLIST" == '' ]] && [[ "$NNLIST" == '' ]]; then
        rm -Rf "$SRCBUCKET"
    fi
    
    if [[ "$OKLIST" == '' ]] && [[ "$RMLIST" == '' ]] && [[ "$MVLIST" == '' ]] && [[ "$BRLIST" == '' ]] && [[ "$ERLIST" == '' ]] && [[ "$NNLIST" == '' ]]; then
        echo '\r\nEMPTY BATCH'
        #grey
        osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$LOGPATH\" to 7"
    fi
fi
