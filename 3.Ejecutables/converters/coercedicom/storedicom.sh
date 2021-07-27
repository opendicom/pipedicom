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
# 6 WRITE_RESP
# 7 CURL_VERBOSE


# LOOPS: ORG < MOD < E < BUCKET

cd $1
ORGS=$(ls)
for ORG in "${ORGS[@]}"; do
    cd $ORG
    
    if [[ $5 == *"+"* ]]; then
        URLPREFIX="${5%+*}"
        URLSUFFIX="${5#*+}"
        URL="$URLPREFIX""$ORG""$URLSUFFIX" 
    else
        URL=$5
    fi
    
    MODS=$(ls)
    for MOD in "${MODS[@]}"; do
        cd $MOD
        
        STUDIES=$(ls)
        for STUDY in "${STUDIES[@]}"; do
            cd $STUDY
    
            BUCKETS=$(ls)
            for BUCKET in "${BUCKETS[@]}"; do
                cd $BUCKET

                if [[ $* == *"CURL_VERBOSE"* ]]
                then
                    STORERESP=$( cat * | curl -v -X POST -H "Content-Type: multipart/related; type=\"application/dicom\"; boundary=myboundary" "$URL" --data-binary @- )
                else
                    STORERESP=$( cat * | curl -X POST -H "Content-Type: multipart/related; type=\"application/dicom\"; boundary=myboundary" "$URL" --data-binary @- )
                fi

                if [[ -z $STORERESP ]]
                then
                    echo "$SECONDS" "$ORG" "$MOD" "$STUDY" "$BUCKET" 'no response'
                else
                
                    #response
                
                    if [[ $STORERESP == *00081198* ]]
                    then
                        #FailedSOPSequence
                        echo $STORERESP
                         #http://dicom.nema.org/medical/dicom/current/output/chtml/part18/sect_6.6.html#table_6.6.1-4
                        DSTBUCKETDIR="$3"/"$ORG"/"$MOD"/"$STUDY"/"$BUCKET"
                         
                    elif [[ $STORERESP == *00081199* ]]
                    then
                         #WarningSOPSequence
                         echo $STORERESP
                         DSTBUCKETDIR="$4"/"$ORG"/"$MOD"/"$STUDY"/"$BUCKET"
                    else
                        if [[ $* == *"WRITE_RESP"* ]] 
                        then
                            echo $STORERESP
                        fi
                        DSTBUCKETDIR="$2"/"$ORG"/"$MOD"/"$STUDY"/"$BUCKET"
                    fi   
                    [ ! -d "$DSTBUCKETDIR" ] && mkdir -p "$BUCKETDIR"                    
                    mv "$BUCKET"/* "$BUCKETDIR"               
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