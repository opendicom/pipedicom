#!/bin/bash

admin=$1
org=$2
branch=$3

cd "$(dirname $0)"

./opendicom/cdamwldicom/install.sh "$admin" "$org" "$branch" 'https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE/instances?Modality=OT&amp;00080080='"$branch"'&amp;SeriesDescription=solicitud&amp;NumberOfStudyRelatedInstances=1&amp;StudyDate='

./opendicom/coercedicom/install.sh "$admin" "$org" "$branch"

//no se installa storedicom (already installed in 1)
