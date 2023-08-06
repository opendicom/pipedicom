#!/bin/sh
# cleanOriginals
# $1: ORIGINALS path (absolute path)
# $2: recent days preserved
# $3: DICOMweb url
#     IRP='http://127.0.0.1:8080/dcm4chee-arc/aets/IRP/rs'
#     saluduy='https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE'

# qido: https://dicom.nema.org/medical/dicom/current/output/chtml/part04/sect_C.3.4.html

# output
# list of study paths (ended by  \)
# can be used to recycle manually:
# mv \
# paths of the list corresponding to a device \
# path to common CLASSIFIED folder of this device

# depth 3 $1/deviceAET/EUID/SUID
find "$1" -depth 3 -type d -Btime +"$2"d -print0 | while read -d $'\0' SERIESPATH
do
    # SERIESPATH absolute
    cd $SERIESPATH
    ORIGINALSCOUNT=$(find . -type f -name "*.dcm" | wc -l )
    if (( $ORIGINALSCOUNT == 0 )); then
        rm -Rf $SERIESPATH
    else
        SERIESUID=${SERIESPATH##*/}
        QIDOJSON=$( curl -s -f "$3"'/series?SeriesInstanceUID='"$SERIESUID" )
        if [[ "$QIDOJSON" = '' ]]; then
            echo "${SERIESPATH%/*}"' \\'
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

