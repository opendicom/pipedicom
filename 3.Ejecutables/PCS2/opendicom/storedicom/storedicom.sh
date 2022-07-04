#!/bin/sh

#$1 org path
#           /spool/branch/dev/study/series/dcm.part
SEND="$1/SEND"
MISMATCHSERVICE="$1/MISMATCH_SERVICE"
SENT="$1/SENT"
LOG="$1/LOG"
ORG=$(basename $1)

STOWENDPOINT=$2
#'https://serviciosridi.preprod.asse.uy/dcm4chee-arc/stow/DCM4CHEE'
#URL=${2%@*}$(basename $1)${2#*@}
QIDOENDPOINT=$3
#'https://serviciosridi.preprod.asse.uy/dcm4chee-arc/qido/DCM4CHEE'
TIMEOUT=$4


if [ ! -d "$SEND" ]; then
   mkdir -p "$SEND"
fi
cd $SEND
for BRANCH in `ls`; do
   cd $BRANCH
   for DEVICE in `ls`; do
      cd $DEVICE
      LOGDEVICE="$LOG"'/'"$BRANCH"'/'"$DEVICE"
      if [ ! -d "$LOGDEVICE" ]; then
          mkdir -p "$LOGDEVICE"
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
                STORERESP=$( cat $SERIES/* /Users/Shared/opendicom/storedicom/myboundary.tail | curl -k -s -X POST -H "Content-Type: multipart/related; type=\"application/dicom\"; boundary=myboundary" "$STOWENDPOINT/studies" --data-binary @- )

                if [[ -z $STORERESP ]] || [[ $"STORERESP" == '<html><head><title>Error</title></head><body>Internal Server Error</body></html>' ]]; then
                   >&2 echo 'MISMATCH_SERVICE '"$BRANCH"'/'"$DEVICE"'/'"$STUDY"'/'"$SERIES"
                else #response
                   # echo 'RESPONSE '"$BRANCH"'/'"$DEVICE"'/'"$STUDY"'/'"$SERIES" #log to stdout

                   LOGPATHDIR="$LOGDEVICE"'/'"$STUDY"
                   if [ ! -d "$LOGPATHDIR" ]; then
                      mkdir -p "$LOGPATHDIR"
                   fi
                   if [[ $STORERESP == *"NativeDicomModel"* ]]; then
                      LOGPATH="$LOGPATHDIR"'/'"$SERIES"'.sh'
                      LOGPATHEXISTS=FALSE
                      if [ -f "$LOGPATH" ]; then
                          LOGPATHEXISTS=TRUE
                      fi

                      echo $STORERESP | xsltproc --stringparam qido "$QIDOENDPOINT" --stringparam org "$ORG" --stringparam branch "$BRANCH" --stringparam device "$DEVICE" --stringparam euid "$STUDY" --stringparam suid "$SERIES" --stringparam logpath "$LOGPATH" /Users/Shared/opendicom/storedicom/respParsing.xsl - >> "$LOGPATH"
                      chmod 744 "$LOGPATH"
                      DEST="$SENT"'/'"$BRANCH"'/'"$DEVICE"'/'"$STUDY"'/'"$SERIES"
                   else
                      # other kind of response
                      echo $STORERESP  >> "$LOGPATHDIR"'/'"$SERIES"'.txt'
                      DEST="$MISMATCHSERVICE"'/'"$BRANCH"'/'"$DEVICE"'/'"$STUDY"'/'"$SERIES"
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
   done #DEVICE
   cd ..
done #BRANCH
