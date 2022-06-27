#!/bin/sh
#name: sop2dcm4218path.sh
#$1 user
#$2 pass
#$3 url
#$4 database

#stdin:  sop
#stdout: ruta completa del archivo correspondiente o /dev/null si no existe.

while read line; do

sopuid=$( basename ${line} )
path=$( \
export MYSQL_PWD="$2"; \
mysql --raw --skip-column-names -u"$1" -h "$3" -b "$4" \
-e "select filesystem.dirpath, files.filepath from files \
left join filesystem on filesystem.pk=files.filesystem_fk \
left join instance on instance.pk=files.instance_fk \
where instance.sop_iuid = '$sopuid' \
limit 1;" \
| awk -F\\t 'BEGIN{OFS="";ORS=" "}{print  $1 "/" $2}' \
)

if [[ ! $path == '' ]]; then
    echo "$path"
else
   echo	/dev/null
fi

done
exit 0
