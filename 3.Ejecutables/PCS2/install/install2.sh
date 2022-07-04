#!/bin/bash


ADMIN=$1
ORG=$2
BRANCH=$3

/Users/Shared/dcmtk/storescp/install.sh $ADMIN $BRANCH 4097
/Users/Shared/dcmtk/wlmscpfs/install.sh $ADMIN $BRANCH 11113 $ORG
/Users/Shared/opendicom/cdamwldicom/install.sh v $ORG $BRANCH "https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE/instances?Modality=OT&amp;00080080=$BRANCH&amp;SeriesDescription=solicitud&amp;NumberOfStudyRelatedInstances=1&amp;StudyDate="
/Users/Shared/opendicom/coercedicom/install.sh $ADMIN $ORG $BRANCH
