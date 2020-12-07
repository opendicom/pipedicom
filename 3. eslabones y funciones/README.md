# Eslabones de una cadena de procesamiento de objetos DICOM

## Encadenar los eslabones

Para recuperar la linea de información del stdin, el script del comando necesita implementar la estructura siguiente:

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

## referirse a los objetos dicom

Según la fuente o el destino de los objetos dicom a procesar, se puede referir a ellos:
(A) por la ruta al archivo, independientemente de la representación B, X, o J
(B) por la ruta al archivo **dicom binario**
(X) por la ruta al archivo **dicom xml**
(J) por la ruta al archivo **dicom json**
(P) por la ruta al archivo **dicom plist** ( [[headstrings],[bodystrings],[headdatas],[bodydatas]] )
(I) por el **SOPInstanceUID** del objeto
(S) por el **SeriesInstanceUID** de la serie
(E) por el **StudyInstanceUID** del estudio
(U) por un url, sin precisión del contenido
(W) por un url wado dicom binario
(V) por un url de visualización (siempre final de una cadena

Estas referencias determinan la clasificación de los eslabones en función del tipo de entrada y el tipo de salida. Por ejemplo un eslabon II recibe y envia SOPInstanceUID(s). 

Se pueden enviar uno o más objetos. 

En caso de no tener objetos a enviar, se termina la cadena.

## Eslabon y función

Cualquier transacción con un PACS o cualquier nodo dicom está normalizada por un protocolo estándar. Lo que especializa una transacción son los paramétros específicos del pacs (aet, ip, puerto, url, ...).

Definimos entonces por separado del eslabón específico que realiza una transacción con un pacs particular, una función genérica de acceso al pacs. Cuando se ejecuta el eslabón, este agrega sus parametros específicos al comando y terceriza su ejecución. 

De esta forma, la cadena de eslabones es mucho más legible (porque aparece como una cadena de nombres de comandos sin parametros), y el código genérico de acceso a cualquier PACS está definido una sola vez en la función correspondiente.

| eslabón | función |
|--|--|
| nombre con sigla de la institución | nombre con referencia a la herramienta |
| stdin y stdout para engancharse y enganchar a otro eslabon | stdout con resultado de la transacción |

### Ejemplo de uso de función por un eslabón:

eslabón:

```
#!/bin/sh
# stdin: B
# stdout: B
# name: BCBSUpcs.sh
# tool: BBstow.sh

while read line; do

RESPONSE=$( echo ${line} | ./BBstow.sh http://10.10.21.65:8080/dcm4chee-arc/aets/BCBSU/rs )

echo "${line}"
done
exit 0
```

Observamos que:
- el script es de tipo BB ( ruta de instancia dicom binario en stdin y repetida en stdout)
- se usa la función BBstow.sh para cada ruta de instancia recibida
- se agrega como parámetro el url del servico específico con el cual se realizará la transacción.
- se captura una eventual respuesta de la función en la variable RESPONSE, por si se necesita más procesamiento diferenciado en función de la respuesta.

función:

```
#!/bin/sh
# stdin: B
# stdout: B
# name: BBstow.sh
# param $1: url dicomweb store (also called stow)
# log: /var/log/BBstow.log
# requires: mime.head and mime.tail in the same folder as the executable
# tool: sistem curl

while read line
do

STOWRESP=$( cat mime.head ${line} mime.tail | curl -s -k -H "Content-Type: multipart/related; type=application/dicom; boundary=myboundary" "$1"/studies --data-binary @- )
if [[ -z $STOWRESP ]]; then
    echo "<stow source=\"${line}\"><response contents=\"not received or empty\"/></stow>" >> /var/log/BBstow.log
elif [[ $STOWRESP == *FailureReason* ]]; then 

    FailureReason=$( echo $STOWRESP | sed -E -e 's/^(.*tag=\"00081197\" vr=\"US\"><Value number=\"1\">)([^<]*)(.*)$/\2/')
    if [[ $FailureReason == "49442" ]]; then
        echo "<stow source=\"${line}\"><response FailureReason=\"Referenced Transfer Syntax not supported\"/></stow>" >> /var/log/BBstow.log
    elif [[ $FailureReason == "272" ]]; then
            
# Processing failure or was already stored
        SOPUID=$( echo "${line}" | ./DICMpath2sopuid.sh )
        QIDORESP=$(curl -s -k "$1"/instances?SOPInstanceUID="$SOPUID")
        if [[ -z $QIDORESP ]]; then
            echo "<stow source=\"${line}\" SOPInstanceUID=\"$SOPUID\"><response FailureReason=\"Processing failure\"/></stow>" >> /var/log/BBstow.log
        else
            echo "<stow source=\"${line}\"><response FailureReason=\"already stowed\"/></stow>" >> /var/log/BBstow.log
        fi
        
    elif [[ $FailureReason == "290" ]]; then
        echo "<stow source=\"${line}\"><response FailureReason=\"Referenced SOP Class not supported\"/></stow>" >> /var/log/BBstow.log
    else
        echo "<stow source=\"${line}\"><response FailureReason=\"$FailureReason\"/></stow>" >> /var/log/BBstow.log    
    fi    
elif [[ $STOWRESP == *WarningReason* ]]; then 
    WarningReason=$( echo $STOWRESP | sed -E -e 's/^(.*tag=\"00081196\" vr=\"US\"><Value number=\"1\">)([^<]*)(.*)$/\2/')
    if [[ $WarningReason == "45056" ]]; then
        echo "<stow source=\"${line}\"><response WarningReason=\"Coercion of Data Elements\"/></stow>" >> /var/log/BBstow.log
    elif [[ $WarningReason == "45062" ]]; then
        echo "<stow source=\"${line}\"><response WarningReason=\"Elements Discarded\"/></stow>" >> /var/log/BBstow.log
    elif [[ $WarningReason == "45063" ]]; then
        echo "<stow source=\"${line}\"><response WarningReason=\"Data Set does not match SOP Class\"/></stow>" >> /var/log/BBstow.log
    else
        echo "<stow source=\"${line}\"><response WarningReason=\"$WarningReason\"/></stow>" >> /var/log/BBstow.log    
    fi
elif [[ $STOWRESP == *RetrieveURL* ]]; then
    echo "<stow source=\"${line}\"><response RetrieveURL=\"$( echo $STOWRESP | sed -E -e 's/^(.*UR\"><Value number=\"1\">)([^<]*)(<\/Value><\/DicomAttribute><\/Item>.*)$/\2/')\"/></stow>" >> /var/log/BBstow.log
else
    echo "<stow source=\"${line}\"><response contents=\"not DICOM conformant\"></stow>" >> /var/log/BBstow.log
fi

echo "${line}"
done 
exit 0
```

Observamos que:
- el script es de tipo B- (ruta de instancia dicom binario en stdin)
- requiere el url como parametro 1 ($1)
- documenta la actividad realizada (pedido-respuesta) en /var/log/BBstow.log

## Fin de la cadena

Para no generar correos a root, se termina la cadena con redirección del stdout a /dev/null
