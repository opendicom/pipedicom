# Storedicom

"store" es el nombre DICOMweb  de la función de envio de instancias de objetos DICOM por protocolo http:// POST. Contrastamos "**store**" con "**cstore**" (C-STORE),  que es la antigua versión binaria de esta función por protocolo ACSE (adoptado y especializado por DICOM bajo el nombre DIMSE).

"store" es el protocolo de envio que usa nuestro gestor "storedicom"  de objetos a enviar desde un repositorio hacía un PACS. El gestor envia objetos y los elimina del repositorio una vez comprobado que fueron recibidos exitosamente. El diseño de la función soporta que paralelamente otros procesos rellenen dinamicamente el repositorio.  Es decir que el **repositorio** es una zona de garaje temporario local que permite acumular los objetos antes de su envio a otra máquina por red.

## Prerequisitos

- storedicom.sh es un script bash que usa estructuras de tipo array, por lo cual se requiere una versión reciente. Esta  probado con bash obtenido por brew sobre macos 10.15.7 Catalina
  
  ```
  GNU bash, version 5.1.16(1)-release (x86_64-apple-darwin19.6.0)
  Copyright (C) 2020 Free Software Foundation, Inc.
  License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
  ```

- un gatillador de comandos de terminal recurrentes tipo **cron** (linux) o **launchctl** (macos)

- un **repositorio**: directorio posix dónde se puede leer y escribir (de preferencia ubicado  sobre SSD u otro medio de almacenamiento de acceso rápido).

- un **pacs** que soporta **DICOMweb** store y query.

### Estructuración del repositorio

repositorio/

- **MISMATCH_ENDPOINT/** ... garaje de objetos para los cuales el response no era del tipo esperado <NativeDicomModel>

- **MISMATCH_INTERNAL/**... garaje de objetos para los cuales el response indica que el pacs está demasiado ocupado y no puede atender el request

- **MISMATCH_INSTANCE/**  ... garaje de objetos para los cuales el response indica que el pacs rechazó el objecto

- **SEND/** ... directorio de objetos a enviar
  
  - **branch/** ... un mismo repositorio puede gestionar varias de ellas
    
    - **device/** ... identificación del equipo  de origen. La lista  se escrutina  por orden alfabética, por lo cual  se puede definir un orden de prioridad por ejemplo con un prefijo numérico de dos digitos.
      
      - **study/** ... usamos el formato pid@an^euid (patient id, accession number, study uid)
        
        - **series/** ... tiene que ser series uid obligatoriamente
          
          - **SOPinstance** ... objeto DICOM con formato prefijo opcional, SOPInstanceUID y sufijo .dcm

- Todos los formatos de nombre de directorio o objeto no pueden contener caracteres no autorizados POSIX para  nombre, ni espacio.

- Para device/ eligimos un formato sofisticado:

```
ejemplo: 00^CT1@1.1.1.1^branch

00       = orden de prioridad
CT1      = aet de origen
1.1.1.1  = ip de origen
branch   = aet de destino
```

- El mismo sistema de subdirectorio que estructura SEND/ se repite en los subdirectorios MISMATCH.../

## Parámetros

El script **storedicom.sh** requiere los parametros posicionales siguientes:

1. **mimePart** ...path to file containing parts separator

2. **mimePartsTail** ...path to file containing last part tail

3. **stowEndpoint** ... por ejemplo: 'https://serviciosridi.asse.uy/dcm4chee-arc/stow/DCM4CHEE'

4. **qidoEndpoint** ... por ejemplo: 'https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE'

5. **timeout** ...por ejemplo: 60 (máx seconds from start of the process to start of processing another series)

6. **batchSize** ... por ejemplo: 40 (number of files of a series treated in one pass)

7. **repository** path to repository

## Detalles técnicos

El script encapsula loops para visitar los  varios niveles de la estructura del repositorio hasta los estudios. Se usa recursivamente la sintaxis 

```bash
for item in `ls`;do
  cd $item
  ...
  cd ..
done
```

### POST series

Llegado a nivel estudio se cambia `ls` por `find` para poder agregar parametros de selección adicionales. Por ejemplo:

- **-type d** que selecciona exclusivamente los directorioes

- **-ctime +30s**  que selecciona exclusivamente los items creados hace más de 30 segundos (no lo hemos copiado en el código a continuación) 

```bash
find . -depth 1 -type d -print0 | while read -d $'\0' dot_series; do

   series=${dot_series#*/}  # removes ./ prefix of the find return value
   batch=$(ls "$series" | head -n "$batchSize" | tr '\n' ' ' )
   if [[ batch == " " ]]; then
      rm -Rf "$series"
   else
      cd $series
      declare -a batchArray=( $batch )
      filelist=$( for item in "${batchArray[@]}"; do \
                     echo -n $item $mimepart;        \
                  done;                              \
                  echo -n $mimepartstail             \
                 )
       storeResponse=$( cat $filelist | curl -k -s           \
                        -H "Content-Type: multipart/related; \
                        type=\"application/dicom\";          \
                        boundary=myboundary"                 \
                        "$stowEndpoint/studies"              \
                        --data-binary @-                     \
                       )
```

Notas:

- **find .** devuelve caminos relativos empezando por **./**  (por eso el nombre  **dot_series** punto serie). 

- La linea siguiente usa la magia de bash para recortar strings, para conservar exclusivamente el **SeriesInstanceUID**.

- batch lista  los "$batchSize" primeros objetos de la serie, separandolos con un espacio

- si batch es vacío, se elimina la serie

- sino, se transforma el string lista  de nombre de objetos en array, intercalando siempre referencias  al archivo que contiene el separador **mimePart** (parametro 1) , y al final agrega referencia al  archivo que contiene el  marcador de fin de  multipart **mimePartsTail** (parametro 2).

- El motor de request es curl, sin log `-s` y sin verificación de certificado `-k`

### Parseo de la response

El formato de la response consiste en un  xml <**NativeDicomModel**> que contiene hasta tres elementos principales:

- <RetrieveURL> (para poder hacer un GET de los objetos recientemente añadidos)

- <FailedSOPSequence> (en caso que falló la recepción de algún objeto)

- <ReferencedSopSequence> (que lista los objetos registrados y eventuales coerciones aplicadas a los mismos)

```
 00081190 RetrieveURL
 00081198 FailedSOPSequence
          00081150 ReferencedSOPClassUID
          00081155 ReferencedSOPInstanceUID
          00081197 FailureReason
 00081199 ReferencedSopSequence
          00081150 ReferencedSOPClassUID
          00081155 ReferencedSOPInstanceUID
          00081190 RetrieveURL
          00081196 WarningReason
          04000561 OriginalAttributesSequence
                   04000550 ModifiedAttributesSequence
                            ...
                   04000562 AttributeModificationDateTime
                   04000563 ModifyingSystem
                   04000564 SourceOfPreviousValues
```

Examinamos sucesivamente los casos de respuesta siguientes:

- **PACS UNREACHABLE** (no response). No se hacer nada

- **pacs busy** (error de jboss). Se mueve la serie a MISMATCH_INTERNAL

- **strange store response** (respuesta no <NativeDicomModel>). Se mueve la serie a MISMATCH_ENDPOINT

- análysis de los 3 elementos de <NativeDicomModel> :
  
  - no FailedSOPSequence, borrado del batch.
  
  - sino
    
    - extracción de la lista de objetos "referenced" 
    
    - borrado de ellos
    
    - extracción de la lista de objetos "failed"
    
    - se mueven a MISMATCH_INSTANCE
  
  - En caso que había un warning, se le copia al log


