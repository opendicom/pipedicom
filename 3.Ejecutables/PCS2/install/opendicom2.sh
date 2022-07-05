#!/bin/bash

ADMIN=$1
ORG=$2
BRANCH=$3

# user

su $ADMIN

# opendicom/cdamwldicom/install.sh
echo '/Users/Shared/opendicom/cdamwldicom/install.sh' "$ADMIN" "$ORG" "$BRANCH" 'https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE/instances?Modality=OT&amp;00080080='"$BRANCH"'&amp;SeriesDescription=solicitud&amp;NumberOfStudyRelatedInstances=1&amp;StudyDate='
/Users/Shared/opendicom/cdamwldicom/install.sh "$ADMIN" "$ORG" "$BRANCH" 'https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE/instances?Modality=OT&amp;00080080='"$BRANCH"'&amp;SeriesDescription=solicitud&amp;NumberOfStudyRelatedInstances=1&amp;StudyDate='
