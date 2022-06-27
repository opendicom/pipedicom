#!/bin/sh
#name: CIPsop2dcm4218path.sh
#stdin:  sop
#stdout: file full path in storage

#include: sop2dcm4218path.sh
#$1 user
#$2 pass
#$3 url
#$4 database

while read line; do

basename ${line} |./sop2dcm4218path.sh apppacs-img APPPACS-IMG 127.0.0.1 RDBPACS

done
exit 0
