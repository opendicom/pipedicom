#!/bin/bash
# https://dicom.nema.org/medical/dicom/current/output/chtml/part04/sect_C.3.4.html

#DICOMWEB='http://127.0.0.1:8080/dcm4chee-arc/aets/IRP/rs'
#DICOMWEB='https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE'

# o locally original
# - exists remotely, removed locally
# · exists remotely, could not removedslocally

echo START
#STUDY is an ABSOLUTE path (not a relative one)
#  -depth 2
#  -Btime +"$2"d
device=$( pwd )
find . -depth 2 -type d -print0 | while read -d $'\0' SERIESPATH
do
    cd "$SERIESPATH"
    ORIGINALSCOUNT=$(find . -type f -name "*.dcm" | wc -l )
    if (( $ORIGINALSCOUNT == 0 )); then
        echo'RM EMPTY '"$SERIESPATH"
        rm -Rf $SERIESPATH
    else
        SERIESUID=${SERIESPATH##*/}
        QIDOJSON=$( curl -s -f 'https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE/series?SeriesInstanceUID='"$SERIESUID" )
        if [[ "$QIDOJSON" = '' ]]; then
            echo 'NOT IN PACS '"$SERIESPATH"
        else
            # (0020,1209) Number of Series Related Instances
            REMOTECOUNT=$( echo $QIDOJSON | sed -e 's/.*00201209//' -e 's/[^\[]*\[//'  -e 's/\].*//')

            if (( $ORIGINALSCOUNT == $REMOTECOUNT )); then
                echo "REMOVE $REMOTECOUNT"' '"$SERIESPATH"
                cd "$device"
                rm -Rf "$SERIESPATH"
               
            else
                echo "$SERIESPATH"
                echo "R/L       $REMOTECOUNT $ORIGINALSCOUNT"
                #remove instances already available remotely
                
                INSTANCELIST=$( curl -s -f 'https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE/instances?SeriesInstanceUID='"$SERIESUID" )
                list=$( ls )
                for SOPPS in $list; do
                    #echo $SOPPS
                    SOPP=${SOPPS%.dcm}
                    SOP=${SOPP:3}
                    if [[ "$INSTANCELIST" == *"$SOP"* ]]; then # found by qido request
                        if [[ `rm -f $SOPPS` == '' ]]; then
                           echo -n -
                        else
                           echo -n ·
                        fi
                    else
                        echo -n o
                    fi
                done
                echo '|'
            fi # distinct instance count
        fi # QIDOJSON response
    fi # non empty folder
    cd "$device"
done #while SEREISPATH
echo END

