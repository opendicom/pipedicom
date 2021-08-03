   #!/bin/sh
SECONDS=0
PATH=$PATH:/usr/local/bin:/usr/bin

# PARAMS:

SEND=$1
MISMATCHSERVICE=$2
SENT=$3
REJECTED=$4
STOREURL=$5 (with %@ for PACS ORG AET found at first level of SEND
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
#          00081197 FailureReason
           if [[ $FAILEDSOPSQ != '' ]]; then
            #http://dicom.nema.org/medical/dicom/current/output/chtml/part18/sect_6.6.html#table_6.6.1-4
            numbers=$(echo $FAILEDSOPSQ | sed 's/[^0-9\.>]*//g')
            numberArray=(${numbers//>/ })
            numberSize=${#numberArray[@]}
            for (( i=0; i<$numberSize; i++)); do
             if [[ ${numberArray[$i]} = '00081155' ]];then
              if [[ ${numberArray[$i+3]} = '00081197' ]]; then
               failure=${numberArray[$i+5]}/
              else
               failure='0'
              fi
              DSTBUCKETDIR="$REJECTED"'/'"$ORG"'/'"$SOURCE"'/'"$STUDY"'/'"$failure"'/'"$BUCKET"'/'
              if [ ! -d "$DSTBUCKETDIR" ]; then
               mkdir -p "$DSTBUCKETDIR"
              fi
              mv ${numberArray[$i+2]}'.dcm.part' "$DSTBUCKETDIR"
             fi
            done
            echo $STORERESP > "$REJECTED"'/'"$ORG"'/'"$SOURCE"'/'"$STUDY"'/.'"$BUCKET"'.response'
           fi


# 00081199 ReferencedSopSequence
#          00081197 WarningReason
#          00081190 RetrieveURL
           if [[ $REFERENCEDSOPSQ != '' ]]; then
            numbers=$(echo $REFERENCEDSOPSQ | sed 's/[^0-9\.>]*//g')
            numberArray=(${numbers//>/ })
            numberSize=${#numberArray[@]}
            for (( i=0; i<$numberSize; i++)); do
             if [[ ${numberArray[$i]} = '00081155' ]];then
             
              if [[ $i < numberSize-5 ]] && [[ ${numberArray[$i+3]} = '00081197' ]]; then
               warning=${numberArray[$i+5]}
              elif [[ $i < numberSize-8 ]] && [[ ${numberArray[$i+6]} = '00081197' ]]; then
               warning=${numberArray[$i+8]}
              else
               warning='0'
              fi
              DSTBUCKETDIR="$SENT"'/'"$ORG"'/'"$SOURCE"'/'"$STUDY"'/'"$warning"'/'"$BUCKET"'/'
              if [ ! -d "$DSTBUCKETDIR" ]; then
               mkdir -p "$DSTBUCKETDIR"
              fi
              mv ${numberArray[$i + 2]}'.dcm.part' "$DSTBUCKETDIR"
             fi
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
