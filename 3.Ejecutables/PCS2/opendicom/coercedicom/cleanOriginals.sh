#!/bin/sh
# $1: ORIGINALS path

# requires jq loop series sum up 0020,1209 Number of Series Related Instances by mod
# https://dicom.nema.org/medical/dicom/current/output/chtml/part04/sect_C.3.4.html

#DICOMWEB='http://127.0.0.1:8080/dcm4chee-arc/aets/IRP/rs'
DICOMWEB='https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE'
#STUDY is an ABSOLUTE path (not a relative one)
find "$1" -depth 2 -type d -Btime +0d -print0 | while read -d $'\0' STUDY
do
    cd $STUDY
    ORIGINALSCOUNT=$(ls */*.dcm | wc -l )
    if (( $ORIGINALSCOUNT == 0 )); then
        rm -Rf "$STUDY"
        if [ ! -d "$STUDY" ]; then
            echo 'Removed empty: '"$STUDY"
        else
            echo 'Could not remove empty: '"$STUDY"
        fi
    else

        echo '----------------------------------------------------------------------------------------------------------------'
        echo "$STUDY"
        if [[ "$STUDY" == *'/.'* ]]; then
            continue;
        fi

#find mod of ORIGINALS
        DIRPATH=$(dirname "$STUDY")
        if [[ $DIRPATH == '.' ]]; then
            DIRPATH=''
        else
            DIRPATH="$DIRPATH"'/'
        fi
        DEVPATH=$(pwd)'/'"$DIRPATH"
        DEVNAME=$(basename $DEVPATH)
        ORIGINALSMOD=${DEVNAME%%@*}
        if [[ $ORIGINALSMOD == 'SRe' ]] || [[ $ORIGINALSMOD == 'SRd' ]]; then
            ORIGINALSMOD='SR'
        fi
#find mods in study
        STUDYUID=${STUDY##*/}
        QIDOJSON=$( curl -s -f "$DICOMWEB"'/series?StudyInstanceUID='"$STUDYUID" )
        QIDOJSON="${QIDOJSON//\\/\\\\}"
        #  | sed -e 's/.*00201208//' -e 's/.*\[//'  -e 's/\].*//')
        # MODSINSTUDY=$( echo $QIDOJSON | jq -r '.[0]|.["00080061"]|.Value|.[]' )

        PATID=$( echo "$QIDOJSON" | jq -r '.[0]|.["00100020"]|.Value|.[]' )
        STUDYDATE=$( echo "$QIDOJSON" | jq -r '.[0]|.["00080020"]|.Value|.[]' )
        echo '('"$STUDYDATE"'.'"$PATID"')'

        SERIESCOUNT=$( echo "$QIDOJSON" | jq length)
        echo "$SERIESCOUNT"' series'
        echo '--------------'
        index=0
        MODSUM=0
        while [ $index -ne $SERIESCOUNT ]; do
            printf '%04d ' "$index"
        
            SERIESNUM=$(echo "$QIDOJSON" | jq --argjson index "$index" -r '.[$index]|.["00200011"]|.Value|.[]')
            printf '%04d : ' "$SERIESNUM"

            SERIESMOD=$(echo "$QIDOJSON" | jq --argjson index "$index" -r '.[$index]|.["00080060"]|.Value|.[]')
            INSTANCESINSERIES=$(echo "$QIDOJSON" | jq --argjson index "$index" -r '.[$index]|.["00201209"]|.Value|.[]')

            if    [[ "$ORIGINALSMOD" == 'SC' ]]      \
            &&    [[ "$SERIESMOD" == 'CT' ]]         \
            &&    (( $SERIESNUM  > 499 ));         then
                MODSUM=$(( $MODSUM + $INSTANCESINSERIES ))
                echo '      '"$INSTANCESINSERIES"' (SC/CT: '"$(echo $QIDOJSON | jq --argjson index "$index" -r '.[$index]|.["0008103E"]|.Value|.[]')"')'
            elif [[ "$ORIGINALSMOD" == 'CT' ]]      \
            &&   [[ "$SERIESMOD" == 'CT' ]]         \
            &&   (( $SERIESNUM  > 499 ));         then
                echo '      '"$INSTANCESINSERIES"' (CT/SC: '"$(echo $QIDOJSON | jq --argjson index "$index" -r '.[$index]|.["0008103E"]|.Value|.[]')"')'
            elif [[ "$SERIESMOD" == 'SEG' ]] && [[ "$ORIGINALSMOD" = 'SG' ]]; then
                MODSUM=$(( $MODSUM + $INSTANCESINSERIES ))
                echo "$INSTANCESINSERIES"
            elif [[ "$SERIESMOD" == "$ORIGINALSMOD" ]]; then
                MODSUM=$(( $MODSUM + $INSTANCESINSERIES ))
                echo "$INSTANCESINSERIES"
            else
                echo '      '"$INSTANCESINSERIES"' '"$SERIESMOD"
            fi
            index=$(($index+1))
        done
        echo '--------------'
        echo 'found in pacs: '"$MODSUM"'   (local: '"$ORIGINALSCOUNT"')'

        if (( $MODSUM > 0 )); then
            if (( $ORIGINALSCOUNT < $MODSUM )); then
                echo 'less instances locally than remotely. Clean each sop instance individually'
                
                #remove instances already available remotely
                #SOPDCM=${INSTANCE##*/}
                for SOPDCM in *; do
                    SOP=${SOPDCM%.*}
                    
                    printf "$SOP"
                    QIDORESPONSE=$( curl -s -f "$DICOMWEB"'/instances?SOPInstanceUID='"$SOP" )
                    
                    #echo "$QIDORESPONSE"
                    if [[ $QIDORESPONSE == "["* ]]; then # found by qido request
                        rm -Rf "$SOPDCM"
                        if [ ! -e "$SOPDCM" ]; then
                            echo ' removed'
                        else
                            echo ' could not remove-e '
                        fi
                    else
                        echo ' ¡RECYCLE!'
                    fi
                done
                
            elif (( $ORIGINALSCOUNT == $MODSUM )); then
                rm -Rf "$STUDY"
                if [ ! -d "$STUDY" ]; then
                    echo 'same number local and remote. Removed local'
                else
                    echo 'same number local and remote. Failed to remove local'
                fi
            else
                echo 'more instances locally. Should recycle '"$STUDY"
            fi
        else
            echo 'no remote instance. Should recycle'"$STUDY"
        fi
    fi
done #while STUDY
