#!/bin/bash

ADMIN=$1
ORG=$2
BRANCH=$3

# system

echo "/Users/Shared/dcmtk/storescp/install.sh $ADMIN $BRANCH 4096"
/Users/Shared/dcmtk/storescp/install.sh "$ADMIN" "$BRANCH" 4097

echo "/Users/Shared/dcmtk/wlmscpfs/install.sh $ADMIN $BRANCH 11112 $ORG"
/Users/Shared/dcmtk/wlmscpfs/install.sh "$ADMIN" "$BRANCH" 11113 "$ORG"


# user

su "$ADMIN"

# opendicom/cdamwldicom/install.sh
echo '/Users/Shared/opendicom/cdamwldicom/install.sh' "$ADMIN" "$ORG" "$BRANCH" 'https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE/instances?Modality=OT&amp;00080080='"$BRANCH"'&amp;SeriesDescription=solicitud&amp;NumberOfStudyRelatedInstances=1&amp;StudyDate='
/Users/Shared/opendicom/cdamwldicom/install.sh "$ADMIN" "$ORG" "$BRANCH" 'https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE/instances?Modality=OT&amp;00080080='"$BRANCH"'&amp;SeriesDescription=solicitud&amp;NumberOfStudyRelatedInstances=1&amp;StudyDate='

# opendicom/coercedicom/install.sh'
echo '/Users/Shared/opendicom/coercedicom/install.sh' "$ADMIN" "$ORG" "$BRANCH"
/Users/Shared/opendicom/coercedicom/install.sh "$ADMIN" "$ORG" "$BRANCH"
