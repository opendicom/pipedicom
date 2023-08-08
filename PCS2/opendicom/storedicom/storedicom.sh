#!/bin/bash
execDir=$(dirname $0)
mimepart="$execDir"'/mimepart'
mimepartstail="$execDir"'/mimepartstail'
org=$(basename $1)
#$1=org paths
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
#60
batchSize=$5
#40

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
            if [[ `ls $study` == '' ]]; then
               rm -Rf "$study"
               echo "[$isoDate] $branch/$device/$study"' empty & deleted'
            else
cd $study
               isoDate=$(date +%Y/%m/%d_%H:%M:%S)
               echo "[$isoDate] $branch/$device/$study"

               #for series in `ls`; do
               find . -depth 1 -type d -print0 | while read -d $'\0' dot_series; do
                  series=${dot_series#*/}  # removes ./ prefix of the find return value
                  
                  batch=$(ls "$series" | head -n "$batchSize" | tr '\n' ' ' )
#echo "$series"': '${#batch}
                  if (( ${#batch} < 2)); then
                     echo "$series"' empty & deleted'
                     rm -Rf "$series"
                  else

cd $series

                     declare -a batchArray=( $batch )
                     filelist=$( for item in "${batchArray[@]}"; do echo -n ' ' $mimepart  ' ' $item; done; echo -n ' ' $mimepartstail )
#echo 'POST'
#echo 'cd '`pwd`'; cat '"$filelist"' | curl -k -s -H "Content-Type: multipart/related; type=\"application/dicom\"; boundary=myboundary" "https://serviciosridi.preprod.asse.uy/dcm4chee-arc/stow/DCM4CHEE/studies" --data-binary @-'
#echo POST end

                     storeResponse=$( cat $filelist | curl -k -s -H "Content-Type: multipart/related; type=\"application/dicom\"; boundary=myboundary" "$stowEndpoint/studies" --data-binary @- )

                     #storeResponse=$( cat $batch /Users/Shared/opendicom/storedicom/myboundary.tail | curl -k -s -H "Content-Type: multipart/related; type=\"application/dicom\"; boundary=myboundary" "$stowEndpoint/studies" --data-binary @- )
                     
cd ..
#series
                     if [[ -z $storeResponse ]];then
                        #Leave series in send
                        >&2 echo 'PACS UNREACHABLE'
                     elif [[ $storeResponse == '<html><head><title>Error</title></head><body>Internal Server Error</body></html>' ]]; then
                        echo 'INTERNAL SERVER ERROR'
                        mkdir -p   "$mismatch_internal/$branch/$device/$study"
                        mv $series "$mismatch_internal/$branch/$device/$study"
                     else #pacs response
#echo $storeResponse
                        if [[ $storeResponse != *"NativeDicomModel"* ]]; then
                           # response does NOT come from DICOMweb store service
                           >&2 echo "NOT NativeDicomModel RESPONSE\r $storeResponse"
                           echo 'mkdir '"$mismatch_endpoint/$branch/$device/$study"
                           mkdir -p   "$mismatch_endpoint/$branch/$device/$study"
                           mv $series "$mismatch_endpoint/$branch/$device/$study"
                        else #DICOM response
                           echo -n "$series"
cd $series
                           if [[ $storeResponse != *FailedSOPSequence* ]]; then
                              # everything is OK
#echo 'rm -f '"$batch"
                              rm -f $batch
                              echo ' batch stored & deleted'
                           else # some instances failed
                              echo ' batch with failure'
#echo $storeResponse > "$1/$series"
                              referenced=$(echo $storeResponse | xsltproc  /Users/Shared/opendicom/storedicom/listReferenced.xsl -)
                              declare -a referencedArray=( $referenced )
                              #list files that can be removed
                              for sopiuid in "${referencedArray[@]}"; do
                                 find . -depth 1 -name "*$sopiuid.dcm" -delete
                                 echo '+ '"$sopiuid"' stored & deleted'
                              done

                              #check if failure(s) are due to duplication
                              failed=$( echo $storeResponse | xsltproc  /Users/Shared/opendicom/storedicom/listFailed.xsl - )
                              declare -a failedArray=( $failed )
                              #remove file if sopiuid exists in pacs
                              mismatch_series="$mismatch_instance/$branch/$device/$study/$series"
                              #list instances available of the series in the pacs
                              qidoResponse=$( curl -s -f "$qidoEndpoint/instances?SeriesInstanceUID=$series" )
                              for sopiuid in "${failedArray[@]}";do
                                 if [[ $qidoResponse == *"$sopiuid"* ]]; then #exists
                                    echo '- '"$sopiuid"' duplicate deleted'
                                    find . -depth 1 -name "*$sopiuid.dcm" -delete
                                 else
                                    mkdir -p $mismatch_series
                                    bad=$( find . -depth 1 -name "*$sopiuid.dcm" )
                                    mv "$bad" "$mismatch_series"
                                    echo '∆ '"$sopiuid"' error moved to mismatch instance'
                                 fi
                              done
                           fi #some instances failed
cd ..
#series

                           if [[ $storeResponse == *WarningReason* ]]; then
                              #echo first warning of the sequence
                              firstWarning=$(echo $storeResponse | xsltproc /Users/Shared/opendicom/storedicom/firstWarning.xsl -)
                              echo "$firstWarning"
                           fi
                        fi #DICOM RESPONSE
                     fi #RESPONSE
                  fi
#series with contents
                  #timeout ?
                  if (( "$SECONDS" > $timeout )); then
                     exit 0
                  fi
               done
               #series
cd ..
#study
            fi
         fi
      done
      #study
      
   cd ..
   done
   #device
   
cd ..
done
#branch