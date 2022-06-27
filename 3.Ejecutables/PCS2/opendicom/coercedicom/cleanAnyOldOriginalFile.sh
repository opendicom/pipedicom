#!/bin/sh
# $1: ORIGINALS path
# $2: recent days preserved
# $3: url dicomweb
# "https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE"
# https://dicom.nema.org/medical/dicom/current/output/chtml/part04/sect_C.3.4.html

#STUDY is an ABSOLUTE path (not a relative one)
find "$1" -type f -name "*.dcm" -Btime +"$2"d -print0 | while read -d $'\0' SOPPATH
do
#    echo $SOPPATH
    SOPDCM=${SOPPATH##*/}
    SOP=${SOPDCM%.dcm}
                
    QIDORESPONSE=$( curl -s -f "$3/instances?00080018=$SOP" )
#    echo "$QIDORESPONSE"
    if [[ "$QIDORESPONSE" == *"$SOP"* ]]; then
       rm -f "$SOPPATH"
       echo 'RM   '"$SOP"
    else
       echo 'SEND '"$SOP"
    fi
done #SOPPATH
