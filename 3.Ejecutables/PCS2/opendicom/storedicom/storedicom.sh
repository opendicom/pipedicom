#!/bin/bash

org=$(basename $1)
#$1=org path
#           /spool/branch/dev/study/series/dcm.part
send="$1/SEND"                          #spool in
mismatch_service="$1/MISMATCH_SERVICE"  #spool out not NativeDicomModel response
mismatch_pacs="$1/MISMATCH_PACS"        #spool out     NativeDicomModel response

stowEndpoint=$2
#'https://serviciosridi.asse.uy/dcm4chee-arc/stow/DCM4CHEE'
qidoEndpoint=$3
#'https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE'
timeout=$4

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
                storeResponse=$( cat $series/* /Users/Shared/opendicom/storedicom/myboundary.tail | curl -k -s -H "Content-Type: multipart/related; type=\"application/dicom\"; boundary=myboundary" "$stowEndpoint/studies" --data-binary @- )

                if [[ -z $storeResponse ]] || [[ $"storeResponse" == '<html><head><title>Error</title></head><body>Internal Server Error</body></html>' ]]; then
                   #pacs not available. Leave series in send
                   >&2 echo "[$isoDate] PACS NOT AVAILABLE"
                   
                else #pacs response

                   if [[ $storeResponse != *"NativeDicomModel"* ]]; then
                       # response does NOT come from DICOMweb store service
                       >&2 echo "[$isoDate] strange store response\r $storeResponse"
                       mv $series "$mismatch_service/$branch/$device/$study"
                      
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
                           for sopiuid in "${failedArray[@]}";do
                              qidoResponse=$( curl -s -f "$qidoEndpoint/instances?SOPInstanceUID=$sopiuid" )
                              if [[ $qidoResponse == "["* ]]; then #exists
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
