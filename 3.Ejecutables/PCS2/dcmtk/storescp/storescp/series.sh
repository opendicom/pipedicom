#!/bin/sh
#$1=dicomPath
#dirname=study UID

dirpath=$( dirname $1)
euid=$( basename $dirpath)
echo $euid

dcm=$(head -c 30000 $1 | tail -c 29000)
posteuid=${dcm#*$euid}
suidattr=${posteuid:5:64}
suid=${suidattr%%[[:space:]]*}
echo $suid
