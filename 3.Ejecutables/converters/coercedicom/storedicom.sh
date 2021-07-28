   #!/bin/sh
SECONDS=0
PATH=$PATH:/usr/local/bin:/usr/bin

# PARAMS:

# 1 SEND
# 2 SENT
# 3 REJECTED
# 4 WARNING
# 5 STORE URL (with %@ for PACS ORG AET found at first level of SEND
#'https://serviciosridi.preprod.asse.uy/dcm4chee-arc/stow/'"DCM4CHEE"'/studies'
# 6 CURL_VERBOSE

cd $1
if [ ! -z "$(ls -A)" ]; then
   for ORG in *; do
   if [ -z "$(ls "$ORG")" ]; then
          rm -Rf "$ORG"
   else
          cd $ORG

          if [[ $5 == *"+"* ]]; then
              URLPREFIX="${5%+*}"
              URLSUFFIX="${5#*+}"
              URL="$URLPREFIX""$ORG""$URLSUFFIX"
          else
              URL=$5
          fi

          for SOURCE in *; do
              if [ -z "$(ls "$SOURCE")" ]; then
                 rm -Rf "$SOURCE"
              else
echo $SOURCE
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

                               if [[ $* == *"CURL_VERBOSE"* ]]
                               then
                                   STORERESP=$( cat * | curl -X POST -H "Content-Type: multipart/related; type=\"application/dicom\"; boundary=myboundary" "$URL" --data-binary @- )
                               else
                                   STORERESP=$( cat * | curl -X POST -H "Content-Type: multipart/related; type=\"application/dicom\"; boundary=myboundary" "$URL" --data-binary @- )
                               fi

                               if [[ -z $STORERESP ]]
                               then
                                   echo "$ORG"/"$SOURCE"/"$STUDY"/"$BUCKET"/ 'no response'
                                   cd ..
                               else
                                   #response

                                   if [[ $STORERESP == *00081198* ]]
                                   then
                                       #FailedSOPSequence
                                        #http://dicom.nema.org/medical/dicom/current/output/chtml/part18/sect_6.6.html#table_6.6.1-4
                                       DSTBUCKETDIR="$3"/"$ORG"/"$SOURCE"/"$STUDY"/"$BUCKET"/

                                   elif [[ $STORERESP == *00081199* ]]
                                   then
                                        #WarningSOPSequence
                                     DSTBUCKETDIR="$4"/"$ORG"/"$SOURCE"/"$STUDY"/"$BUCKET"/
                                   else
                                       DSTBUCKETDIR="$2"/"$ORG"/"$SOURCE"/"$STUDY"/"$BUCKET"/
                                   fi
                                   if [ ! -d "$DSTBUCKETDIR" ]
                                   then
                                       mkdir -p "$DSTBUCKETDIR"
                                   fi
                                   mv * "$DSTBUCKETDIR"
                                   echo $STORERESP > "$DSTBUCKETDIR"'.response'
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
