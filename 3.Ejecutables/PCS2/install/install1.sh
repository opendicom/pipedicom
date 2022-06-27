#!/bin/bash
# $1= (aet)
# $2= (admin user name - storescp is run from root, received files are chowned to admin user name)

if [ "$#" = 2 ]; then
    ADMIN=pcs2
else
    ADMIN=$2
fi

/Users/Shared/dcmtk/storescp/install.sh $1 4096 $ADMIN
/Users/Shared/dcmtk/wlmscpfs/install.sh $1 11112 DCM4CHEE
/Users/Shared/opendicom/cdamwldicom/install.sh $1 DCM4CHEE "https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE/instances?Modality=OT&amp;00080080=$1&amp;SeriesDescription=solicitud&amp;NumberOfStudyRelatedInstances=1&amp;StudyDate=";
/Users/Shared/opendicom/coercedicom/install.sh $1 DCM4CHEE;

/Users/Shared/opendicom/storedicom/install.sh DCM4CHEE "https://serviciosridi.asse.uy/dcm4chee-arc/stow/DCM4CHEE/studies";
