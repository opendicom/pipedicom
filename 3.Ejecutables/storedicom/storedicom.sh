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
echo 'url:'$URL
   for SOURCE in *; do
    if [ -z "$(ls "$SOURCE")" ]; then
     rm -Rf "$SOURCE"
    else
echo 'source:'$SOURCE
     cd $SOURCE

     for STUDY in *; do
      if [ -z "$(ls "$STUDY")" ]; then
       rm -Rf "$STUDY"
      else
echo 'study:'$STUDY
       cd $STUDY

       for BUCKET in *; do
        if [[ $BUCKET == *".xml" ]]; then
         rm -f $BUCKET
        elif [ -z "$(ls "$BUCKET")" ]; then
         rm -Rf "$BUCKET"
        else
echo 'bucket:'$BUCKET
         cd $BUCKET
         find . -name '.DS_*' -exec rm -rf {} \;

         if [[ CURL_VERBOSE == *"CURL_VERBOSE"* ]]; then
          STORERESP=$( cat * | curl -X POST -H "Content-Type: multipart/related; type=\"application/dicom\"; boundary=myboundary" "$URL" --data-binary @- )
         else
          STORERESP=$( cat * | curl -X POST -H "Content-Type: multipart/related; type=\"application/dicom\"; boundary=myboundary" "$URL" --data-binary @- )
         fi

         if [[ -z $STORERESP ]]; then
          echo '<noresponse/>' >$ORG"/"$SOURCE"/"$STUDY"/"$BUCKET"'.xml'
          cd ..
         else
#response
echo $STORERESP
          if [[ $STORERESP == *"NativeDicomModel"* ]]; then


# 00081190 RetrieveURL


# 00081198 FailedSOPSequence
#          00081150 ReferencedSOPClassUID
#          00081155 ReferencedSOPInstanceUID
#          00081197 FailureReason

NOREFERENCEDSOPSQ=$(echo $STORERESP |  tr '\12' '\40' | sed 's/<DicomAttribute.keyword="ReferencedSOPSequence".tag="00081199.*//')
FAILEDSOPSQ=$(echo $NOREFERENCEDSOPSQ | sed 's/.*"00081198//')
FAILEDRESP='<?xml version="1.0" encoding="UTF-8"?><NativeDicomModel xml-space="preserved"><DicomAttribute keyword="FailedSOPSequence" tag="00081198'"$FAILEDSOPSQ"'</NativeDicomModel>'

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
#echo 'tokens failed : '"$numbers"
             if [[ $i < numberSize-4 ]] && [[ ${numberArray[$i+2]} = '00081197' ]]; then
              failure=${numberArray[$i+4]}
             else
              failure='0'
             fi
             DSTBUCKETDIR="$REJECTED"'/'"$ORG"'/'"$SOURCE"'/'"$STUDY"'/'"$failure"'/'"$BUCKET"
             if [ ! -d "$DSTBUCKETDIR" ]; then
              mkdir -p "$DSTBUCKETDIR"
             fi
             FILENAME=${numberArray[$i+1]}'*'
echo `ls $FILENAME`
echo '->'$DSTBUCKETDIR
             mv `ls $FILENAME` "$DSTBUCKETDIR"
            done

            echo $FAILEDRESP > "$REJECTED"'/'"$ORG"'/'"$SOURCE"'/'"$STUDY"'/'"$BUCKET"'.xml'
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

REFERENCEDSOPSQ=$(echo $STORERESP |  tr '\12' '\40' | sed 's/.*00081199\" vr=\"SQ\">//')
REFERENCEDSOPRESP="$REFERENCEDSOPSQ"'<?xml version="1.0" encoding="UTF-8"?><NativeDicomModel xml-space="preserved"><DicomAttribute keyword="ReferencedSOPSequence" tag="00081199" vr="SQ">'

           if [[ $REFERENCEDSOPSQ != '' ]]; then
echo'referenced:'
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

             FILENAME=${numberArray[$i+1]}'*'
echo `ls $FILENAME`
echo '->'$DSTBUCKETDIR
             mv `ls $FILENAME` "$DSTBUCKETDIR"
            done

            echo $REFERENCEDSOPRESP > "$SENT"'/'"$ORG"'/'"$SOURCE"'/'"$STUDY"'/'"$BUCKET".xm'
           fi


          else
           DSTBUCKETDIR="$MISMATCHSERVICE"'/'"$ORG"'/'"$SOURCE"'/'"$STUDY"'/'"$BUCKET"'/'
           if [ ! -d "$DSTBUCKETDIR" ]; then
            mkdir -p "$DSTBUCKETDIR"
           fi
           mv * "$DSTBUCKETDIR"
           echo $STORERESP > "$MISMATCHSERVICE"'/'"$ORG"'/'"$SOURCE"'/'"$STUDY"'/.'"$BUCKET"'_response'
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
