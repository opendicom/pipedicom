# Cadena de procesamiento

## Encadenar eslabones

Para recuperar la linea de información del stdin, el script necesita implementar la estructura siguiente:

```
#!/bin/sh

while read line; do

echo "${line}"

done 

exit 0
```

la variable ${line} recibe stdin. 

`echo` crea una linea en stdout. 

Este script es apenas un proxy sin modificación del stream.

Para hacer algo útil, colocar lineas de código entre do y done en base. Puden referirse a los argumentos del comando y al stdin. Se crea el stdout mediante uno o más comandos `echo`.


## Eslabon particular de ejecutable genérico

Definimos por separado el eslabón que contiene los detalles de configuración, del  ejecutable genérico que usa. 

### Ejemplo de uso de función por un eslabón:

eslabón:

```
#!/bin/sh
# stdin: Ruta
# stdout: Ruta
# name: BCBSUpcs.sh
# tool: stow.sh

while read line; do

RESPONSE=$( echo ${line} | ./stow.sh http://10.10.21.65:8080/dcm4chee-arc/aets/BCBSU/rs )

echo "${line}"
done
exit 0
```

Observamos que:
- el script recibe ruta en stdin y la repite en stdout
- se usa la función stow.sh para cada ruta de instancia recibida
- se agrega como parámetro el url del servico específico con el cual se realizará la transacción en este eslabón
- se captura una eventual respuesta de la función en la variable RESPONSE, por si se necesita más procesamiento en función de la respuesta.

ejecutable:

```
#!/bin/sh
# name: stow.sh
# param $1: url dicomweb store (also called stow)
# log: /var/log/stow.log
# requires: mime.head and mime.tail in the same folder as the executable
# tool: sistem curl

while read line
do

STOWRESP=$( cat mime.head ${line} mime.tail | curl -s -k -H "Content-Type: multipart/related; type=application/dicom; boundary=myboundary" "$1"/studies --data-binary @- )
if [[ -z $STOWRESP ]]; then
    echo "<stow source=\"${line}\"><response contents=\"not received or empty\"/></stow>" >> /var/log/stow.log
elif [[ $STOWRESP == *FailureReason* ]]; then 

    FailureReason=$( echo $STOWRESP | sed -E -e 's/^(.*tag=\"00081197\" vr=\"US\"><Value number=\"1\">)([^<]*)(.*)$/\2/')
    if [[ $FailureReason == "49442" ]]; then
        echo "<stow source=\"${line}\"><response FailureReason=\"Referenced Transfer Syntax not supported\"/></stow>" >> /var/log/stow.log
    elif [[ $FailureReason == "272" ]]; then
            
# Processing failure or was already stored
        SOPUID=$( echo "${line}" | ./DICMpath2sopuid.sh )
        QIDORESP=$(curl -s -k "$1"/instances?SOPInstanceUID="$SOPUID")
        if [[ -z $QIDORESP ]]; then
            echo "<stow source=\"${line}\" SOPInstanceUID=\"$SOPUID\"><response FailureReason=\"Processing failure\"/></stow>" >> /var/log/stow.log
        else
            echo "<stow source=\"${line}\"><response FailureReason=\"already stowed\"/></stow>" >> /var/log/stow.log
        fi
        
    elif [[ $FailureReason == "290" ]]; then
        echo "<stow source=\"${line}\"><response FailureReason=\"Referenced SOP Class not supported\"/></stow>" >> /var/log/stow.log
    else
        echo "<stow source=\"${line}\"><response FailureReason=\"$FailureReason\"/></stow>" >> /var/log/stow.log    
    fi    
elif [[ $STOWRESP == *WarningReason* ]]; then 
    WarningReason=$( echo $STOWRESP | sed -E -e 's/^(.*tag=\"00081196\" vr=\"US\"><Value number=\"1\">)([^<]*)(.*)$/\2/')
    if [[ $WarningReason == "45056" ]]; then
        echo "<stow source=\"${line}\"><response WarningReason=\"Coercion of Data Elements\"/></stow>" >> /var/log/stow.log
    elif [[ $WarningReason == "45062" ]]; then
        echo "<stow source=\"${line}\"><response WarningReason=\"Elements Discarded\"/></stow>" >> /var/log/stow.log
    elif [[ $WarningReason == "45063" ]]; then
        echo "<stow source=\"${line}\"><response WarningReason=\"Data Set does not match SOP Class\"/></stow>" >> /var/log/stow.log
    else
        echo "<stow source=\"${line}\"><response WarningReason=\"$WarningReason\"/></stow>" >> /var/log/stow.log    
    fi
elif [[ $STOWRESP == *RetrieveURL* ]]; then
    echo "<stow source=\"${line}\"><response RetrieveURL=\"$( echo $STOWRESP | sed -E -e 's/^(.*UR\"><Value number=\"1\">)([^<]*)(<\/Value><\/DicomAttribute><\/Item>.*)$/\2/')\"/></stow>" >> /var/log/stow.log
else
    echo "<stow source=\"${line}\"><response contents=\"not DICOM conformant\"></stow>" >> /var/log/stow.log
fi

echo "${line}"
done 
exit 0
```

## Fin de la cadena

Para no generar correos a root, se termina la cadena con redirección del stdout a /dev/null
