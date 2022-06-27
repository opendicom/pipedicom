#!/bin/bash
export DCMDICTPATH=/Users/Shared/dcmtk/dicom.dic
/usr/local/bin/wlmscpfs -ll debug -dfr -cs1 -nse +xe -dfp /Users/Shared/dcmtk/wlmscpfs/$1/aet/published $2 2>&1
