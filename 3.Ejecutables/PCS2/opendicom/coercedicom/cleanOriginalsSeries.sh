#!/bin/sh
# $1: ORIGINALS path
# $2: recent days preserved
# $3: DICOMweb url
# https://dicom.nema.org/medical/dicom/current/output/chtml/part04/sect_C.3.4.html

#DICOMWEB='http://127.0.0.1:8080/dcm4chee-arc/aets/IRP/rs'
#DICOMWEB='https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE'

#STUDY is an ABSOLUTE path (not a relative one)
find "$1" -depth 3 -type d -Btime +"$2"d -print0 | while read -d $'\0' SERIESPATH
do
    cd $SERIESPATH
    ORIGINALSCOUNT=$(find . -type f -name "*.dcm" | wc -l )
    if (( $ORIGINALSCOUNT == 0 )); then
        rm -Rf $SERIESPATH
    else
        SERIESUID=${SERIESPATH##*/}
        QIDOJSON=$( curl -s -f "$3"'/series?SeriesInstanceUID='"$SERIESUID" )
        if [[ "$QIDOJSON" = '' ]]; then
            echo 'series '"$SERIESPATH"' not available remotely'
        else
            # (0020,1209) Number of Series Related Instances
            REMOTECOUNT=$( echo $QIDOJSON | sed -e 's/.*00201209//' -e 's/[^\[]*\[//'  -e 's/\].*//')

            if (( $ORIGINALSCOUNT == $REMOTECOUNT )); then
                rm -Rf $SERIESPATH
            else
                #remove instances already available remotely
                #SOPDCM=${INSTANCE##*/}
                
                INSTANCELIST=$( curl -s -f "$3"'/instances?SeriesInstanceUID='"$SERIESUID" )

                for SOPDCM in `ls`; do
                    SOP=${SOPDCM%.dcm}

                    if [[ "$INSTANCELIST" == *"$SOP"* ]]; then # found by qido request
                        rm -f $SOPDCM
                    fi
                done
            fi # distinct instance count
        fi # QIDOJSON response
    fi # non empty folder
done #while SEREISPATH

