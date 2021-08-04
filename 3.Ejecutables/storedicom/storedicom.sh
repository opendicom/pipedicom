#!/bin/sh
SEND=$1
MISMATCHSERVICE=$2
SENT=$3
REJECTED=$4
STOREURL=$5
# with %@ for PACS ORG AET found at first level of SEND
#'https://serviciosridi.preprod.asse.uy/dcm4chee-arc/stow/'"DCM4CHEE"'/studies'
CURLVERBOSE=$6


cd $SEND
if [ ! -z "$(ls -A)" ]; then
 for ORG in *; do
  if [ -z "$(ls "$ORG")" ]; then
   rm -Rf "$ORG"
  else
   cd $ORG

   if [[ $STOREURL == *"+"* ]]; then
    URLPREFIX="${STOREURL%+*}"
    URLSUFFIX="${STOREURL#*+}"
    URL="$URLPREFIX""$ORG""$URLSUFFIX"
   else
    URL=$STOREURL
   fi

   for SOURCE in *; do
    if [ -z "$(ls "$SOURCE")" ]; then
     rm -Rf "$SOURCE"
    else
#echo $SOURCE
     cd $SOURCE

     for STUDY in *; do
      if [ -z "$(ls "$STUDY")" ]; then
       rm -Rf "$STUDY"
      else
       cd $STUDY

       for BUCKET in *; do
        if [ -z "$(ls "$BUCKET")" ]; then
         rm -Rf "$BUCKET"
        else
         cd $BUCKET

         if [[ CURL_VERBOSE == *"CURL_VERBOSE"* ]]; then
          STORERESP=$( cat * | curl -X POST -H "Content-Type: multipart/related; type=\"application/dicom\"; boundary=myboundary" "$URL" --data-binary @- )
         else
          STORERESP=$( cat * | curl -X POST -H "Content-Type: multipart/related; type=\"application/dicom\"; boundary=myboundary" "$URL" --data-binary @- )
         fi

         if [[ -z $STORERESP ]]; then
          echo "$ORG"/"$SOURCE"/"$STUDY"/"$BUCKET"/ 'no response'
          cd ..
         else
#response
          if [[ $response == *"NativeDicomModel"* ]]; then
           REFERENCEDSOPSQ=$(echo $response |  tr '\12' '\40' | sed 's/.*00081199//s')
           NOREFERENCEDSOPSQ=$(echo $response |  tr '\12' '\40' | sed 's/00081199.*//s')
           FAILEDSOPSQ=$(echo $NOREFERENCEDSOPSQ | sed 's/.*00081198//s')

# 00081190 RetrieveURL


# 00081198 FailedSOPSequence
#          00081150 ReferencedSOPClassUID
#          00081155 ReferencedSOPInstanceUID
#          00081197 FailureReason

           if [[ $FAILEDSOPSQ != '' ]]; then
           
            #loop for each 00081155.*
            FAILEDSOPSQ=$(echo $FAILEDSOPSQ 00081155)
            FAILEDSOPSQ=${FAILEDSOPSQ#*00081155}
            while [[ $FAILEDSOPSQ ]]; do
             FAILEDSOP=${FAILEDSOPSQ%%00081155*}
             FAILEDSOPSQ=${FAILEDSOPSQ#*00081155}

             numbers=$(echo $FAILEDSOP | sed 's/[^0-9\.>]*//g')
             numberArray=(${numbers//>/ })
             numberSize=${#numberArray[@]}
#echo 'tokens failed : '"$numberSize"
             if [[ $i < numberSize-4 ]] && [[ ${numberArray[$i+2]} = '00081197' ]]; then
              failure=${numberArray[$i+4]}/
             else
              failure='0'
             fi
             DSTBUCKETDIR="$REJECTED"'/'"$ORG"'/'"$SOURCE"'/'"$STUDY"'/'"$failure"'/'"$BUCKET"'/'
             if [ ! -d "$DSTBUCKETDIR" ]; then
              mkdir -p "$DSTBUCKETDIR"
             fi
             mv ${numberArray[$i+2]}'.dcm.part' "$DSTBUCKETDIR"
            done
            echo $STORERESP > "$REJECTED"'/'"$ORG"'/'"$SOURCE"'/'"$STUDY"'/.'"$BUCKET"'.response'
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

            #loop for each 00081155.*
            REFERENCEDSOPSQ=$(echo $REFERENCEDSOPSQ 00081155)
            REFERENCEDSOPSQ=${REFERENCEDSOPSQ#*00081155}
            while [[ $REFERENCEDSOPSQ ]]; do
             REFERENCEDSOP=${REFERENCEDSOPSQ%%00081155*}
             REFERENCEDSOPSQ=${REFERENCEDSOPSQ#*00081155}
      
             numbers=$(echo $REFERENCEDSOPSQ | sed 's/[^0-9\.>]*//g')
             numberArray=(${numbers//>/ })
             numberSize=${#numberArray[@]}
             if [[ $i < numberSize-4 ]] && [[ ${numberArray[$i+2]} = '00081196' ]]; then
               warning=${numberArray[$i+4]}
             elif [[ $i < numberSize-7 ]] && [[ ${numberArray[$i+5]} = '00081196' ]]; then
               warning=${numberArray[$i+7]}
             else
              warning='0'
             fi
             DSTBUCKETDIR="$SENT"'/'"$ORG"'/'"$SOURCE"'/'"$STUDY"'/'"$warning"'/'"$BUCKET"'/'
             if [ ! -d "$DSTBUCKETDIR" ]; then
              mkdir -p "$DSTBUCKETDIR"
             fi
             mv ${numberArray[$i + 2]}'.dcm.part' "$DSTBUCKETDIR"
            done
            echo $STORERESP > "$SEND"'/'"$ORG"'/'"$SOURCE"'/'"$STUDY"'/.'"$BUCKET"'.response'
           fi
          else
           # response is not ann xml NativeDicomModel
           DSTBUCKETDIR="$MISMATCHSERVICE"/"$ORG"/"$SOURCE"/"$STUDY"/"$BUCKET"/
           if [ ! -d "$DSTBUCKETDIR" ]; then
            mkdir -p "$DSTBUCKETDIR"
           fi
           mv * "$DSTBUCKETDIR"
           echo $STORERESP > "$DSTBUCKETDIR"'.response'
          fi
          cd ..
          rm -Rf "$BUCKET"
         fi
         #RESPONSE
        fi
       done
       #BUCKET
      cd ..
     fi
    done
    #STUDY
    cd ..
   fi
  done
  #SOURCE
  cd ..
 fi
done
fi
#ORG
