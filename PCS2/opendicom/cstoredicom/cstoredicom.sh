#!/bin/sh

# requires dcmtk installed in /usr/local/bin

SEND="$1"
SENT="$2"
WARN="$3"
AET="$4"
AEC="$5"
IP="$6"
PORT="$7"
TS="$8"

# SEND, CLASSIFIED and REJECTED has the same internal structure source/study/series/instance.dcm
NOW=$(date '+%s')
#24 * 3600 = 86400
YESTERDAY=$((NOW-86400))
mkdir -p "$SEND"
cd $SEND
for SOURCE in `ls`; do
   cd $SOURCE
   for STUDY in `ls`; do
      if [ -d $STUDY ]; then #STUDYISDIR
         if [ "$(ls $STUDY)" ];then #STUDYDIRNOTEMPTY
            cd $STUDY
            # find series not empty last modified since more than 30 seconds
            find . -depth 1 -type d  ! -empty -mtime +30s -print0 | while read -d $'\0' SERIES
            do
               LOG=$( /usr/local/bin/storescu -ll warn +sd +r +sp "*.dcm" -R +C "$TS" -aet "$AET" -aec "$AEC" "$IP" "$PORT" "$SERIES" )

               if [[ "$LOG" == '' ]]; then
                  DEST="$SENT"'/'"$SOURCE"'/'"$STUDY"
                
               else #move to REJECTED
                  >&2 echo 'NOT SENT '"$SOURCE"'/'"$STUDY"'/'"$SERIES"'\r\n'"$WARN"
                  DEST="$WARN"'/'"$SOURCE"'/'"$STUDY"
               fi
               
               mkdir -p "$DEST"
               mv $SERIES $DEST
            done #SERIES
            cd ..
         else # STUDY was empty
            # if has been empty for 24 hours
            if [[ "$(ls $STUDY)" = '' ]] && (( $(stat -f "%m" $STUDY) < $YESTERDAY ));then
               rm -Rf $STUDY
            fi
         fi  #STUDYDIRNOTEMPTY
      fi #STUDYISDIR
   done #STUDY
   cd ..
done #SOURCE
