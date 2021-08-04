#!/bin/sh

response=$(cat $1)
if [[ $response == *"NativeDicomModel"* ]]; then
  REFERENCEDSOPSQ=$(echo $response |  tr '\12' '\40' | sed 's/.*00081199//')
  NOREFERENCEDSOPSQ=$(echo $response |  tr '\12' '\40' | sed 's/00081199.*//')
  FAILEDSOPSQ=$(echo $NOREFERENCEDSOPSQ | sed 's/.*00081198//')


# 00081190 RetrieveURL



# 00081198 FailedSOPSequence
#          00081150 ReferencedSOPClassUID
#          00081155 ReferencedSOPInstanceUID
#          00081197 FailureReason

  if [[ $FAILEDSOPSQ != '' ]]; then
    DSTBUCKETDIR="REJECTED"
    
    #loop for each 00081155.*
    FAILEDSOPSQ=$(echo $FAILEDSOPSQ 00081155)
    FAILEDSOPSQ=${FAILEDSOPSQ#*00081155}
    while [[ $FAILEDSOPSQ ]]; do
      FAILEDSOP=${FAILEDSOPSQ%%00081155*}
      FAILEDSOPSQ=${FAILEDSOPSQ#*00081155}
      
      numbers=$(echo $FAILEDSOP | sed 's/[^0-9\.>]*//g')
      numberArray=(${numbers//>/ })
      numberSize=${#numberArray[@]}
#echo 'tokens failed: '"$numbers"
      if [[ $i < numberSize-4 ]] && [[ ${numberArray[$i+2]} = '00081197' ]]; then
        reason=${numberArray[$i+4]}/
      else
        reason='0'
      fi
      echo "$DSTBUCKETDIR"/"$reason""${numberArray[$i + 1]}"'.dcm.part'
    done
  fi


# 00081199 ReferencedSopSequence
#          00081150 ReferencedSOPClassUID
#          00081155 ReferencedSOPInstanceUID
#          00081190 RetrieveURL
#          00081196 WarningReason
#          04000561 OriginalAttributesSequence
#                   04000550 ModifiedAttributesSequence
#                            ...
#                   04000562 AttributeModificationDateTime
#                   04000563 ModifyingSystem
#                   04000564 SourceOfPreviousValues


  if [[ $REFERENCEDSOPSQ != '' ]]; then
    DSTBUCKETDIR="SENT"

    #loop for each 00081155.*
    REFERENCEDSOPSQ=$(echo $REFERENCEDSOPSQ 00081155)
    REFERENCEDSOPSQ=${REFERENCEDSOPSQ#*00081155}
    while [[ $REFERENCEDSOPSQ ]]; do
      REFERENCEDSOP=${REFERENCEDSOPSQ%%00081155*}
      REFERENCEDSOPSQ=${REFERENCEDSOPSQ#*00081155}
      
      numbers=$(echo $REFERENCEDSOP | sed 's/[^0-9\.>]*//g')
      numberArray=(${numbers//>/ })
      numberSize=${#numberArray[@]}
      if [[ $i < numberSize-4 ]] && [[ ${numberArray[$i+2]} = '00081196' ]]; then
        warning=${numberArray[$i+4]}/
      elif [[ $i < numberSize-7 ]] && [[ ${numberArray[$i+5]} = '00081196' ]]; then
        warning=${numberArray[$i+7]}
      else
        warning='0'
      fi
      echo "$DSTBUCKETDIR"/"$warning"/"${numberArray[$i + 1]}"'.dcm.part'
    done
  fi

else
  # response is not ann xml NativeDicomModel
  DSTBUCKETDIR="MISMATCHSERVICE"/
  echo "$DSTBUCKETDIR"
fi
