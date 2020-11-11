#!/bin/sh
#name: sopuid2CIPpacspath.sh
#stdin:  I
#stdout: B

# recibe UID de SOPInstance, y busca en el pacs de CIP y devuelve la ruta completa del archivo correspondiente o /dev/null si no existe.

while read line; do

sopuid=$( basename ${line} )
path=$( \
export MYSQL_PWD=APPPACS-IMG; \
mysql --raw --skip-column-names -uapppacs-img -h 127.0.0.1 -b RDBPACS \
-e "select filesystem.dirpath, files.filepath from files \
left join filesystem on filesystem.pk=files.filesystem_fk \
left join instance on instance.pk=files.instance_fk \
where instance.sop_iuid = '$sopuid' \
limit 1;" \
| awk -F\\t 'BEGIN{OFS="";ORS=" "}{print  $1 "/" $2}' \
)

if [[ ! $path == '' ]];	then
    echo "$path"
else
   echo	/dev/null
fi

done
exit 0