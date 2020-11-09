#!/bin/sh

# sr2img.sh
# Copyright 2020 __opendicom.com__. All rights reserved.

#  $1 = path a new sr

# sends the corrected xml version of the olf sr to CIP apppacs-img
# in case of BLUE CROSS, creates /var/spool/BCBSU/"$SOPUID" with corrected xml
# in case of MEDICINA PERSONALIZADA /var/spool/MP/"$SOPUID" with corrected xml

cd /opt/dcm4che-2.0.24/bin

#retain only the latest instance of the series
CURINSTANCEFOLDER=$(dirname $1)'/*'
LATEST=$(ls -tr $CURINSTANCEFOLDER | head -1)

TIMESTAMP=$(date --rfc-3339='ns')
echo "-----------------------------------"  >> /var/log/sr2img.log
echo "$TIMESTAMP"  >> /var/log/sr2img.log
echo $LATEST  >> /var/log/sr2img.log
OLDXML=$( ./dcm2xml $LATEST )

SOPUID=$( echo $OLDXML \
| java -cp saxon9he.jar net.sf.saxon.Query \
-s:- \
-qs:"declare option saxon:output 'omit-xml-declaration=yes'; \
/dicom/attr[@tag='00080018']/string()" \
);
echo $SOPUID  >> /var/log/sr2img.log

REQUESTING=$( echo $OLDXML \
| java -cp saxon9he.jar net.sf.saxon.Query \
-s:- \
-qs:"declare option saxon:output 'omit-xml-declaration=yes'; \
/dicom/attr[@tag='00321033']/string()" \
);
echo $REQUESTING  >> /var/log/sr2img.log

NEWXML=$( echo $OLDXML \
| java -jar saxon9he.jar \
-s:- \
-xsl:newsr.xsl \
)


# send the new dicom objecto to apppacs-img
NEWPATH=$( echo "$SOPUID" | ./sopuid2CIPpacspath.sh )
if [[ $NEWPATH != '' ]]; then
    echo "                                                                               existing" >> /var/log/sr2img.log
    echo "$NEWPATH" >> /var/log/sr2img.log
    echo " " >> /var/log/sr2img.log

    # with these permissions, the cron task will not select these files any longer
    for FILENAME in `ls -tr $CURINSTANCEFOLDER`; do
        chmod 454 $FILENAME
    done
        
    # create spool items for specific processings
    if [[ $REQUESTING == *"BLUE CROSS"* ]]; then
        echo $NEWXML > /var/spool/BCBSU/"$SOPUID"
    elif [[ $REQUESTING == *"MEDICINA PERSONALIZADA"* ]]; then
        echo $NEWXML > /var/spool/MP/"$SOPUID"
    fi
    
else

    rm -f /var/tmp/sr2.dcm
    echo $NEWXML | ./xml2dcm -x -o /var/tmp/sr2.dcm  >> /dev/null
    ./dcmsnd -L SR:11111 CIP@192.168.10.123:21112 /var/tmp/sr2.dcm >> /dev/null

    sleep 1

    NEWPATH=$( echo "$SOPUID" | ./sopuid2CIPpacspath.sh )
    if [[ $NEWPATH != '' ]]; then
        echo "                                                                               sent" >> /var/log/sr2img.log
        echo "$NEWPATH" >> /var/log/sr2img.log
        echo " " >> /var/log/sr2img.log
        # with these permissions, the cron task will not select these files any longer
        for FILENAME in `ls -tr $CURINSTANCEFOLDER`; do
            chmod 454 $FILENAME
        done
        
        # create spool items for specific processings
        if [[ $REQUESTING == *"BLUE CROSS"* ]]; then
            echo $NEWXML > /var/spool/BCBSU/"$SOPUID"
        elif [[ $REQUESTING == *"MEDICINA PERSONALIZADA"* ]]; then
            echo $NEWXML > /var/spool/MP/"$SOPUID"
        fi
        
    else
        echo "                                                                               failed" >> /var/log/sr2img.log
    fi
fi