#!/bin/bash

if [ "$#" -ne 7 ]; then
   echo 'installService'
   echo '$1= (admin user name)'
   echo '$2= (service)'
   echo '$3= (pcs aet)'
   echo '$4= (pcs port)'
   echo '$5= (pacsweb aet)'
   echo '$6= (pacsweb url)'
else

   if [ "$2" = 'storescp' ]; then
       /Users/Shared/dcmtk/storescp/install.sh $3 $4 $1 wheel
   elif [ "$2" = 'coercedicom' ]; then
       /Users/Shared/opendicom/coercedicom/install.sh $3 $5 $1
   elif [ "$2" = 'storedicom' ]; then
       /Users/Shared/opendicom/storedicom/install.sh $5 $6
       # "https://serviciosridi.asse.uy/dcm4chee-arc/stow/DCM4CHEE/studies"
   elif [ "$2" = 'cdawldicom' ]; then
       /Users/Shared/opendicom/cdamwldicom/install.sh $3 $5 $1
       #"https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE/instances?Modality=OT&amp;00080080=$1&amp;SeriesDescription=solicitud&amp;NumberOfStudyRelatedInstances=1&amp;StudyDate=";
   elif [ "$2" = 'wlmscpfs' ]; then
       /Users/Shared/dcmtk/wlmscpfs/install.sh $3 $4 $5 $1
   fi
   
fi
