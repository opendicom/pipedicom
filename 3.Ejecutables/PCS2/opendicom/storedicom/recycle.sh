#!/bin/sh
# used by log.sh

#environment variables required
if [[ $SENTSERIES == '' ]] || [[ $SENDSERIES == '' ]] || [[ $LOGPATH == '' ]] || [[ $QIDOENDPOINT == '' ]]; then
    echo SENTSERIES, SENDSERIES, LOGPATH, QIDOENDPOINT environment variables required
else

#color codes

# 6 green   OKLIST  found remote,           not found local
# 4 blue    RMLIST  found remote,           removed local
# 5 purple  MVLIST  not found remote,       recycled local
# 3 yellow  BRLIST  bad response remote,    found local
# 1 orange  ERLIST  bad answer from remote
# 2 red     NNLIST  found Neither remote    Nor local
# 7 grey    no list empty bucket


#params = list of filenames of failed files to be recycled, removed or need investigation
    

    OKLIST=''
    NNLIST=''
    ERLIST=''

    RMLIST=''
    MVLIST=''
    BRLIST=''
    
    # loop iuid
    for SOPIUID in "$@"; do
        QIDORESPONSE=$( curl -s -f "$QIDOENDPOINT/instances?SOPInstanceUID=$SOPIUID" )
#        QIDORESPONSE=$( curl -s -f 'https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE/instances?SOPInstanceUID='"$SOPIUID" )
        
        FILENAME=$(find "$SENTSERIES" -name "$SOPIUID"'*')
        if [[ $FILENAME == '' ]]; then
# not found locally
            if [[ $QIDORESPONSE == "["* ]]; then
                echo 'OK '
                OKLIST="$OKLIST""$SOPIUID"'\r\n'
            elif [[ $QIDORESPONSE == '' ]]; then
                echo 'NN '
                NNLIST="$NNLIST""$SOPIUID"'\r\n'
            else
                echo '\r\nER '"$SOPIUID"'\r\n'
                echo "$QIDORESPONSE"'\r\n'
                ERLIST="$ERLIST""$SOPIUID"'\r\n'
            fi
        else
# found locally
            if [[ $QIDORESPONSE == "["* ]]; then # found by qido request
                echo 'RM '
                rm -f "$FILENAME"
                RMLIST="$RMLIST""$SOPIUID"'\r\n'
            elif [[ $QIDORESPONSE == '' ]]; then
                # recycle in SEND directory
                echo 'MV '
                if [ ! -d "$SENDSERIES" ]; then
                    mkdir -p "$SENDSERIES"
                fi
                mv "$SENTSERIES""$FILENAME" "$SENDSERIES"
                MVLIST="$MVLIST""$SOPIUID"'\r\n'
            else # response not json
                echo '\r\nBR '"$SOPIUID"'\r\n'
                echo "$QIDORESPONSE"'\r\n'
                BRLIST="$BRLIST""$SOPIUID"'\r\n'
            fi
        fi
    done

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
        rm -Rf "$SENTSERIES"
    fi
    
    if [[ "$OKLIST" == '' ]] && [[ "$RMLIST" == '' ]] && [[ "$MVLIST" == '' ]] && [[ "$BRLIST" == '' ]] && [[ "$ERLIST" == '' ]] && [[ "$NNLIST" == '' ]]; then
        echo '\r\nEMPTY BATCH'
        #grey
        osascript -e "tell application \"Finder\" to set label index of alias POSIX file \"$LOGPATH\" to 7"
    fi
fi
