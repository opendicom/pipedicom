#!/bin/bash
export DCMDICTPATH=/Users/Shared/dcmtk/dicom.dic
/usr/local/bin/storescp -ll debug --fork +xe -pm +te -aet $1 -pdu 131072 -dhl -up -g -e -od /Volumes/IN/$1/ARRIVED -su "" -uf -xcr "/Users/Shared/dcmtk/storescp/$1/classifier.sh #a #r #p #f #c" $2 2>&1
