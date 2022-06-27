#!/bin/sh
SEND="$1/SEND"
MISMATCHSERVICE="$1/MISMATCH_SERVICE"
SENT="$1/SENT"
LOG="$1/LOG"
URL=${2%@*}$(basename $1)${2#*@}
#echo $URL
#'https://serviciosridi.preprod.asse.uy/dcm4chee-arc/stow/@/studies'
# @ substituted
XSLT=$3
#used to format xml responses
#$4 TIMOUT in seconds

if [ ! -d "$SEND" ]; then
   mkdir -p "$SEND"
fi
cd $SEND
for ORG in `ls`; do
   cd $ORG
   for SOURCE in `ls`; do
      cd $SOURCE
      LOGSOURCE="$LOG"'/'"$ORG"'/'"$SOURCE"
      if [ ! -d "$LOGSOURCE" ]; then
          mkdir -p "$LOGSOURCE"
      fi

      for STUDY in `ls`; do
      if [ -d $STUDY ]; then
         #cleaning done at study level.
         #If coercedicom has a new bucket for the study, it will recreate it
         if [ `du -sk "$STUDY" | cut -f1` -le 15 ]; then
            rm -Rf "$STUDY"
         else
             cd $STUDY

             find . -depth 1 -type d  ! -empty -mtime +30s -print0 | while read -d $'\0' DOT_SERIES
             do
                SERIES=${DOT_SERIES#*/}
                STORERESP=$( cat $SERIES/* /Users/Shared/opendicom/storedicom/myboundary.tail | curl -k -s -X POST -H "Content-Type: multipart/related; type=\"application/dicom\"; boundary=myboundary" "$URL" --data-binary @- )

                if [[ -z $STORERESP ]] || [[ $"STORERESP" == '<html><head><title>Error</title></head><body>Internal Server Error</body></html>' ]]; then
                   >&2 echo 'MISMATCH_SERVICE '"$ORG"'/'"$SOURCE"'/'"$STUDY"'/'"$SERIES"
                else #response
                   # echo 'RESPONSE '"$ORG"'/'"$SOURCE"'/'"$STUDY"'/'"$SERIES" #log to stdout

                   LOGPATHDIR="$LOGSOURCE"'/'"$STUDY"
                   if [ ! -d "$LOGPATHDIR" ]; then
                      mkdir -p "$LOGPATHDIR"
                   fi
                   if [[ $STORERESP == *"NativeDicomModel"* ]]; then
                      LOGPATH="$LOGPATHDIR"'/'"$SERIES"'.sh'
                      LOGPATHEXISTS=FALSE
                      if [ -f "$LOGPATH" ]; then
                          LOGPATHEXISTS=TRUE
                      fi

                      echo $STORERESP | xsltproc --stringparam org "$ORG" --stringparam dev "$SOURCE" --stringparam euid "$STUDY" --stringparam bucket "$SERIES" --stringparam logpath "$LOGPATH" /Users/Shared/opendicom/storedicom/respParsing.xsl - >> "$LOGPATH"
                      chmod 744 "$LOGPATH"
                      DEST="$SENT"'/'"$ORG"'/'"$SOURCE"'/'"$STUDY"'/'"$SERIES"
                   else
                      # other kind of response
                      echo $STORERESP  >> "$LOGPATHDIR"'/'"$SERIES"'.txt'
                      DEST="$MISMATCHSERVICE"'/'"$ORG"'/'"$SOURCE"'/'"$STUDY"'/'"$SERIES"
                   fi
                   if [ ! -d "$DEST" ]; then
                      mkdir -p "$DEST"
                   fi
                   mv $SERIES/* $DEST
                fi #RESPONSE
                
                #timeout ?
                if (( "$SECONDS" > $4 )); then
                   exit 0
                fi

             done #SERIES
             cd ..
          fi
      fi
      done #STUDY
      cd ..
   done #SOURCE
   cd ..
done #ORG
