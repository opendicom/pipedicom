#!/bin/bash

org=$(basename $1)
#$1=org path
#           /spool/branch/dev/study/series/dcm.part
send="$1/SEND"                            #spool in
mismatch_internal="$1/MISMATCH_INTERNAL"  #spool out server internal error response
mkdir -p $mismatch_internal
mismatch_endpoint="$1/MISMATCH_ENDPOINT"  #spool out not responsed by pacs
mkdir -p $mismatch_endpoint
mismatch_instance="$1/MISMATCH_INSTANCE"  #spool out NativeDicomModel response, instance error
mkdir -p $mismatch_instance

stowEndpoint=$2
#'https://serviciosridi.asse.uy/dcm4chee-arc/stow/DCM4CHEE'
qidoEndpoint=$3
#'https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE'
timeout=$4
partMax=$5

if [ ! -d "$send" ]; then
   mkdir -p "$send"
fi
cd $send
for branch in `ls`; do
   cd $branch
   for device in `ls`; do
      cd $device
      for study in `ls`; do
      if [ -d $study ]; then
         #cleaning done at study level.
         #If coercedicom has a new SERIES for the study, it will recreate it
         if [ `du -sk "$study" | cut -f1` -le 15 ]; then
            rm -Rf "$study"
         else
             cd $study
             isoDate=$(date +%Y/%m/%d_%H:%M:%S)
             echo "[$isoDate] $branch/$device/$study"

             find . -depth 1 -type d  ! -empty -mtime +30s -print0 | while read -d $'\0' dot_series; do
             
                series=${dot_series#*/}  # removes ./ prefix of the find return value
                cd $series
                storeResponse=$( cat $(ls | head -n $5) /Users/Shared/opendicom/storedicom/myboundary.tail | curl -k -s -H "Content-Type: multipart/related; type=\"application/dicom\"; boundary=myboundary" "$stowEndpoint/studies" --data-binary @- )
                cd ..
                if [[ -z $storeResponse ]];then
                   #Leave series in send
                   >&2 echo "[$isoDate] PACS UNREACHABLE"
                elif [[ $storeResponse == '<html><head><title>Error</title></head><body>Internal Server Error</body></html>' ]]; then
                   #pacs internal server error
                   mkdir -p   "$mismatch_internal/$branch/$device/$study"
                   mv $series "$mismatch_internal/$branch/$device/$study"
                   
                else #pacs response

                   if [[ $storeResponse != *"NativeDicomModel"* ]]; then
                       # response does NOT come from DICOMweb store service
                       >&2 echo "[$isoDate] strange store response\r $storeResponse"
                       mkdir -p   "$mismatch_endpoint/$branch/$device/$study"
                       mv $series "$mismatch_endpoint/$branch/$device/$study"
                      
                   else #DICOM response
                       echo "$series"

                        if [[ $storeResponse != *FailedSOPSequence* ]]; then
                           # everything is OK
                           rm -Rf $series
                           echo "   stored"
                        else # some instances failed
                           cd $series
                           referenced=$(echo $storeResponse | xsltproc  /Users/Shared/opendicom/storedicom/listReferenced.xsl -)
                           declare -a referencedArray=( $referenced )
                           #list files that can be removed
                           for sopiuid in "${referencedArray[@]}"; do
                              rm -f *"$sopiuid"*
                              echo "   stored    $sopiuid"
                           done

                           #check if failure(s) are due to duplication
                           failed=$( echo $storeResponse | xsltproc  /Users/Shared/opendicom/storedicom/listFailed.xsl - )
                           declare -a failedArray=( $failed )
                           #remove file if sopiuid exists in pacs
                           mismatch_series="$mismatch_pacs/$branch/$device/$study/$series"
                           
                           #list instances available of the series in the pacs
                           qidoResponse=$( curl -s -f "$qidoEndpoint/instances?SeriesInstanceUID=$eries" )
                           
                           for sopiuid in "${failedArray[@]}";do
                              if [[ $qidoResponse == *"$sopiuid"* ]]; then #exists
                                 rm -f *"$sopiuid"*
                                 echo "   duplicate $sopiuid"
                              else
                                 mkdir -p $mismatch_series
                                 mv *"$sopiuid"* $mismatch_series
                                 echo "   error     $sopiuid"
                              fi
                           done
                           cd ..
                        fi #

                        if [[ $storeResponse == *WarningReason* ]]; then
                           #echo first warning of the sequence
                           firstWarning=$(echo $storeResponse | xsltproc /Users/Shared/opendicom/storedicom/firstWarning.xsl -)
                           echo "$firstWarning"
                        fi
                    fi #DICOM RESPONSE
                   
                fi #RESPONSE
                
                #timeout ?
                if (( "$SECONDS" > $timeout )); then
                   exit 0
                fi

             done #series
             cd ..
          fi
      fi
      done #study
      cd ..
   done #device
   cd ..
done #branch
