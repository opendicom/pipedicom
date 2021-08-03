#!/bin/sh

response=$(cat $1)
if [[ $response == *"NativeDicomModel"* ]]; then
  REFERENCEDSOPSQ=$(echo $response |  tr '\12' '\40' | sed 's/.*00081199//')
  NOREFERENCEDSOPSQ=$(echo $response |  tr '\12' '\40' | sed 's/00081199.*//')
  FAILEDSOPSQ=$(echo $NOREFERENCEDSOPSQ | sed 's/.*00081198//')

# 00081190 RetrieveURL


# 00081198 FailedSOPSequence
#          00081197 FailureReason
  if [[ $FAILEDSOPSQ != '' ]]; then
    #http://dicom.nema.org/medical/dicom/current/output/chtml/part18/sect_6.6.html#table_6.6.1-4

    DSTBUCKETDIR="REJECTED"
                              
    numbers=$(echo $FAILEDSOPSQ | sed 's/[^0-9\.>]*//g')
    numberArray=(${numbers//>/ })
    numberSize=${#numberArray[@]}
    for (( i=0; i<$numberSize; i++)); do
      if [[ ${numberArray[$i]} = '00081155' ]];then
        if [[ $i < numberSize-5 ]] && [[ ${numberArray[$i+3]} = '00081197' ]]; then
          reason=${numberArray[$i+5]}/
        else
          reason=''
        fi
        echo "$DSTBUCKETDIR"/"$reason""${numberArray[$i + 2]}"'.dcm.part'
      fi
    done
  fi


# 00081199 ReferencedSopSequence
#          00081197 WarningReason
#          00081190 RetrieveURL
  if [[ $REFERENCEDSOPSQ != '' ]]; then
      DSTBUCKETDIR="SENT"
    if [ ! -d "$DSTBUCKETDIR" ]; then
      mkdir -p "$DSTBUCKETDIR"
    fi
    numbers=$(echo $REFERENCEDSOPSQ | sed 's/[^0-9\.>]*//g')
    numberArray=(${numbers//>/ })
    numberSize=${#numberArray[@]}
    for (( i=0; i<$numberSize; i++)); do

      if [[ ${numberArray[$i]} = '00081155' ]];then
        #failure reason?
        if [[ $i < numberSize-5 ]] && [[ ${numberArray[$i+3]} = '00081197' ]]; then
          reason=${numberArray[$i+5]}
          REASONBUCKETDIR=="WARNING"/"$reason"/
          echo "$REASONBUCKETDIR""${arrIN[$i +  2]}"'.dcm.part'
        elif [[ $i < numberSize-8 ]] && [[ ${numberArray[$i+6]} = '00081197' ]]; then
          reason=${numberArray[$i+8]}
          REASONBUCKETDIR=="WARNING"/"$reason"/
          echo "$REASONBUCKETDIR""${numberArray[$i +  2]}"'.dcm.part'
        else
          #no failure reason
          #echo ${arrIN[$i + 2]}
          echo "$DSTBUCKETDIR"/"${numberArray[$i + 2]}"'.dcm.part'
        fi
      fi
    done
  fi
else
  # response is not ann xml NativeDicomModel
  DSTBUCKETDIR="MISMATCHSERVICE"/
  echo "$DSTBUCKETDIR"
fi
