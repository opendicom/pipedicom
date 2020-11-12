#!/bin/sh
#name: IB_CIPpacs.sh
#stdin:  I (sopuid)
#stdout: B (soppath)

#include: IB_dcm4chee218mysql
#$1 user
#$2 pass
#$3 url
#$4 database

while read line; do

basename ${line} |./IB_dcm4chee218mysql apppacs-img APPPACS-IMG 127.0.0.1 RDBPACS

done
exit 0