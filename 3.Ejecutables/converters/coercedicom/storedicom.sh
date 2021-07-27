#!/bin/sh
SECONDS=0
PATH=$PATH:/usr/local/bin:/usr/bin

# PARAMS:

# 1 SEND
# 2 SENT
# 3 REJECTED
# 4 STORE URL (with %@ for PACS ORG AET found at first level of SEND

# LOOPS: ORG < MOD < E < BUCKET

cd $1
ORGS=$(ls)
for ORG in "${ORGS[@]}"; do
    cd $ORG
    
    MODS=$(ls)
    for MOD in "${MODS[@]}"; do
        cd $MOD
        
        STUDIES=$(ls)
        for STUDY in "${STUDIES[@]}"; do
            cd $STUDY
    
            BUCKETS=$(ls)
            for BUCKET in "${BUCKETS[@]}"; do

                FILES


    STOWRESP=$( echo -ne "\r\n--myboundary\r\nContent-Type: application/dicom\r\n\r\n$DCM\r\n--myboundary--" | curl -s -H "Content-Type: multipart/related; type=application/dicom; boundary=myboundary" http://10.200.120.19:8080/dcm4chee-arc/stow/DCM4CHEE/studies --data-binary @- )
    if [[ -z $STOWRESP ]]
    then
    echo "<noResponse/>"
    echo "</stow>"
    echo "<end status=\"failure\" elapsed=\"$SECONDS\"/>"
    else
    
        #response
    
        if [[ $* == *"+debug"* ]]
        then
        echo $STOWRESP > "$TMPFOLDER"/"$STUDYUID"_"$TIMESTAMP"".stow.resp.xml"
        fi
    
    
        FailedSOPSequence=$( echo $STOWRESP \
        | java -cp saxon9.jar net.sf.saxon.Query \
        -s:- \
        -qs:"declare option saxon:output 'omit-xml-declaration=yes'; \
        /NativeDicomModel/DicomAttribute[@tag='00081198']/Item/*" \
        );
        if [[ -n $FailedSOPSequence ]]
        then
            #http://dicom.nema.org/medical/dicom/current/output/chtml/part18/sect_6.6.html#table_6.6.1-4
            echo "$FailedSOPSequence"
            echo "</stow>"
            echo "<end elapsed=\"$SECONDS\" stowResponseMeaning=\"\c"
            FailureReason=$( echo $STOWRESP \
            | java -cp saxon9.jar net.sf.saxon.Query \
            -s:- \
            -qs:"declare option saxon:output 'omit-xml-declaration=yes'; \
            /NativeDicomModel/DicomAttribute[@tag='00081198']/Item/DicomAttribute[@tag='00081197']/Value/text()" \
            );
            if [ "$FailureReason" = "290" ]
            then
            echo "Referenced SOP Class not supported\c"
            elif [ "$FailureReason" = "272" ]
            then
            echo "Processing failure\c"
            elif [ "$FailureReason" = "49442" ]
            then
            echo "Referenced Transfer Syntax not supported\c"
            elif [ "$FailureReason" -gt "42751" ] && [ "$FailureReason" -lt "43008" ]
            then
            echo "out of resources\c"
            elif [ "$FailureReason" -gt "43263" ] && [ "$FailureReason" -lt "43520" ]
            then
            echo "Data Set does not match SOP Class\c"
            elif [ "$FailureReason" -gt "49151" ] && [ "$FailureReason" -lt "53248" ]
            then
            echo "Cannot understand\c"
            else
            echo "unspecified\c"
            fi
    
            echo "\" status=\"failure\"/>"
    
        else
            #no FailedSOPSequence
            ReferencedSOPSequence=$( echo $STOWRESP \
            | java -cp saxon9.jar net.sf.saxon.Query \
            -s:- \
            -qs:"declare option saxon:output 'omit-xml-declaration=yes'; \
            /NativeDicomModel/DicomAttribute[@tag='00081199']/Item/*" \
            );
    
            if [[ -z $ReferencedSOPSequence ]]
            then
            echo "<noReferencedSOPSequence/>"
            echo "</stow>"
            echo "<end status=\"failure\" elapsed=\"$SECONDS\"/>"
            else
    
                #ReferencedSOPSequence
                #http://dicom.nema.org/medical/dicom/current/output/chtml/part18/sect_6.6.html#table_6.6.1-3
                echo "$ReferencedSOPSequence"
                echo "</stow>"
    
                WarningReason=$( echo $STOWRESP \
                | java -cp saxon9.jar net.sf.saxon.Query \
                -s:- \
                -qs:"declare option saxon:output 'omit-xml-declaration=yes'; \
                /NativeDicomModel/DicomAttribute[@tag='00081198']/Item/DicomAttribute[@tag='00081196']/Value/text()" \
                );
    
                if [[ -n $WarningReason ]]
                then
    
                echo "<end elapsed=\"$SECONDS\" stowResponseMeaning=\"\c"
    
                if [ "$WarningReason" = "45056" ]
                then
                echo "Coercion of Data Elements\c"
                elif [ "$WarningReason" = "45062" ]
                then
                echo "Elements Discarded\c"
                elif [ "$WarningReason" = "45063" ]
                then
                echo "Data Set does not match SOP Class\c"
                else
                echo "unspecified\c"
                fi
    
                echo "\" status=\"warning\"/>"
    
                #else
                fi
            done
            #BUCKET
            cd ..
        done
        #STUDY
        cd ..
    done
    #MOD
    cd ..
done
#ORG
