coercedicom
===========

Procesa los directorios y archivos DICOM encontrados en subdirectorios del suddirectorio RECEIVED de un directorio spool. Dentro de RECEIVED, las nuevas imágenes están clasificadas en una estructura a tres niveles:

- DEVICE: La primera subdivisión indica el origen de dónde viene la imagen. Por ejemplo: la carpeta llamada "NXGENRAD@192.168.4.16^1.2^IRP" indica que un equipo identificado por el AET "NXGENRAD" desde el IP local "192.168.4.16" envia por syntaxis 1.2.840.10008.1.2 (implicit endian) al AET "IRP".
- STUDY: La segunda subdivisión está constituida por carpetas con el identificador único de un estudio (EUID) como nombre.
- SERIES: La tercera subdivisión está constituida por carpetas con el identificador único de una serie(SUID) como nombre.
- instance: El tercer nivel, o sea dentro de una carpeta de estudio, son las imágenes que correspondena este estudio, identificadas por su SOPUID.

El procesamiento se realiza en base a las directivas que se encuentran en coercedicom.json.

```
[{
"regex":".*(NXGENRAD|NXMAMMO).*",
"removeFromDataset":[ "00000001_00101010-AS" ],
"coerceDataset":{ "00000001_00080080-LO" :[ "asseMALDONADO" ]},
"supplementToDataset": { "00000001_00081060-PN": [ "asseMALDONADO^-^-"]},
"removeFromEUIDprefixedDataset": { "2.16.858.2" :[ "00000001_00081060-PN",  "00000001_00081030-LO"]},
"sourceAET":"asseMALDONADO",
"receivingAET":"DCM4CHEE",
"storeMode":"DICMhttp11",
"j2kLayers":1
},
{
"regex":".*",
"removeFromDataset":[ "00000001_00101010-AS" ],
"coerceDataset":{ "00000001_00080080-LO" :[ "asseMALDONADO" ]},
"supplementToDataset": { "00000001_00081060-PN": [ "asseMALDONADO^-^-"]},
"removeFromEUIDprefixedDataset": { "2.16.858.2" :[ "00000001_00081060-PN",  "00000001_00081030-LO"]},
"sourceAET":"asseMALDONADO",
"receivingAET":"DCM4CHEE",
"storeMode":"DICMhttp11",
"j2kLayers":1
}]
```

Coercedicom.json es un array de objetos. Cada uno de ellos contiene un regex que permite matchear el [SOURCE] de las imágenes recibidas. El orden de los objetos corresponde a la prioridad acordada a cada uno de ellos. Las directivas incluidas en el objeto aplican a los estudios provenientes de las [SOURCE] que satisfacen el regex.

## MISMATCH_SOURCE, MISMATCH_CDAMWL, MISMATCH_PACS

Cuando aparece un SOURCE que no satisface ningún regex, coercedicom lo mueve a un subdirectorio del  directorio MISMATCH_SOURCE. 

Cuando coercedicom está acoplado a cdamwl, un estudio que demuestra incompatibilidades con el item de MWL correspondiente va a MISMATCH_CDAMWL.

Lo mismo cuando coercedicom está configurado para verificar los datos patronímicos con un pacs de destino, pero esta vez los estudios que generan ambiguëdad a nivel de la identificación del paciente están apartados dentro  de un directorio MISMATCH_PACS

## ORIGINALS, MISMATCH_ALTERNATE y FAILURE

Cuando aparece una imagen de un SOURCE válido, se realizan las operaciones de coerción correspondientes. Tienen por resultado la creación de una nueva imagen, en caso que las operaciones fuesen exitosas. Luego de las operaciones, el original sin modificar está trasladado a una de las carpetas ORIGINALS (si la operación fue exitosa y esta instancia no está ya presente en ORIGINALS) o MISMTATCH_ALTERNATES (si la operación fue exitosa y a instancia lya existe en ORIGINALS) o FAILURE (si no se pudo crear la nueva imagen).

En MISMATCH_ALTERNATE y FAILURE, el nombre está compuesto de SOP instance guión bajo unix time. Permite guardar todas las copias de una instancia.

## SUCCESS

La ruta del dirctorio success tiene lla forma STORE/DICMhttp11|DICMhttp2|DICMhttp3|-xv|-xs|-xi|-xe/pacsAET

DICMhttp11|DICMhttp2|DICMhttp3 implican el uso del HTTP respectivo y envio de contenido binario DICM. 

xv|-xs|-xi|-xe se refiere al transfer syntax de dcmtk, respectivamente jp2k, jpl, implicit y explicit.

Un subdirectorio de SUCCESS recibe las imágenes creadas como resultado de la coerción. Se agregan a la ruta de SUCCESS :

- pacsAET (definido en el json de coercedicom) 
- "SEND" 
- branch (definido en el json de coercedicom)
- DEVICE: Las dos primeras  cifras indican la prioridad. 00 es  la prioridad máxima. Indica el rango del regex interceptor en el archivo coercedicom.json. Las subdivisiones siguientes corresponden al nombre de carpeta recibida en source.
- STUDY: La segunda subdivisión está constituida por carpetas con el identificador único de un estudio (EUID) como nombre.
- SERIES: La tercera subdivisión está constituida por carpetas con el identificador único de una serie(SUID) como nombre.
- instance: El tercer nivel, o sea dentro de una carpeta de estudio, son las imágenes que correspondena este estudio, identificadas por su SOPUID.

Tests
=====

coercedicom aplica :

- (test1) fuente de la información (source) conocida, 
- (test2) compatibilidad de (study) con los items de cdawl (presupone test1 exitoso)
- (test3) compatibilidad de (study) con los datos existentes en el pacs (no implementado en ASSE)

Dependiendo de los resultados:

- Si (test1),(test2) o (test3) falla, la instancia está trasladada a un subdirectorio de SOURCE_MISMATCH, MWL_MISMATCH o PACS_MISMATCH respectivamente.
- Si la coerción falla, la instancia original está trasladada a un subdirectorio de FAILURE.
- Si la coerción es exitosa, la instancia original está trasladada a un subdirectorio de ORIGINALS, y el resultado del procesamiento está colocado dentro de un subdirectorio del directorio SUCCESS. 

(test2) cdawldicom
--------------

cdawldicom construye una lista de trabajo local previo a la realización de los estudios por las modalidades imagenologicas. Las modalidades consultan la lista para obtener la metadata a adjuntar a las imágenes.

## Sistema de archvivos de cdawldicom/audit

```
/scpaet
     /published/EUID.wl
     /completed/EUID.wl
     /canceled/EUID.wl

     /aaaammdd
             /EUID
                 /StudyInstanceUID
                                 /cda.xml
                                 /wl.json
             /AN
                /accessionNumber[^issuer]
                  /symlink StudyInstanceUID -> StudyInstanceUID      
             /PID     
                /patientID[^issuer]
                  /symlink StudyInstanceUID -> StudyInstanceUID        
```

Toda esta información accesible localmente permite realizar multiples tests, que se hubiese usado la lista de trabajo desde la modalidad de imagenología o no.

- (2.1) Buscar correspondencia entre las imágenes producidas y una tarea de la lista. La primera opción es mediante el StudyInstanceUID, que es estructurante de ambos sistemas de archivos para cdawldicom y coercedicom. 

- (2.2.1) La segunda opción es el accessionNumber. Requiere parseo del archivo

- (2.2.2)  La tercera el identificador de paciente. El parseo sirve también para este caso.
  Si la búsqueda no dió resultados, se considera que el estudio es independiente de la cdawldicom y se cierra el segundo capitulo de test. 

- (2.3) Verificación que las informaciones paciente son similares. Si existen diferencias, alertar y colocar en una subcarpeta del directorio RECEIVER con el nombre del problema. Sino realizar la coerción, usando cdawldicom a este efecto.

(test3) Consulta al pacs de destino
-------------------------------

(no instrumentado en ASSE)

# Argumentos del comando

- CDargCmd
- CDargSpool
- CDargSuccess
- CDargFailure
- CDargOriginals
- CDargMismatchAlternates
- CDargMismatchSources
- CDargMismatchCdawl
- CDargMismatchPacs
- CDargcoercedicom,            //archivo json de configuración de las coerciones
- CDargCdamwlDir,               //cdawldicom dir path (if empty, no test2)
- CDargPacsSearch,              //DICOMweb search url (if empty, no test3)
- CDargTimeout,                    //max time in seconds before ending the execution
- CDargMaxSeries,                //max series (negative is monothread)
- CDsinceLastSeriesModif    //min time in seconds without modification in series dir before processing

# coercedicom.json

| Label                                                          | Descripción                                                                                                                                                                                                                                                                                                                                                   |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| regex                                                          | expresión regular que matchea la identificación del source                                                                                                                                                                                                                                                                                                    |
| coercePreambule:                                               | base64 data to be placed as preambule of the dicom file instead of the empty 128 bytes ej:"coercePreamble":"DQotLW15Ym91bmRhcnkNCkNvbnRlbnQtVHlwZTogYXBwbGljYXRpb24vZGljb20NCg0KAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=" |
| coerceBlobs:{}                                                 | replaces or suplements blobs                                                                                                                                                                                                                                                                                                                                  |
| removeFromFileMetainfo:[]                                      | only if attr exists in fileMetainfo                                                                                                                                                                                                                                                                                                                           |
| coerceFileMetainfo:{}                                          | replaces or suplements attrs in fileMetainfo                                                                                                                                                                                                                                                                                                                  |
| replaceInFileMetainfo:{}                                       | only if attr already existed in fileMetainfo                                                                                                                                                                                                                                                                                                                  |
| supplementToFileMetainfo:{}                                    | only if attr did not exist in fileMetainfo                                                                                                                                                                                                                                                                                                                    |
| removeFromEUIDprefixedFileMetainfo:{ "UIDprefix":[atributeID]} | EUIDprefixed permite seleccionar estudios para los cuales se usó EUID de la MWL. Performed last (may undo a previous coercion)                                                                                                                                                                                                                                |
| removeFromDataset:[atributeID]                                 | only if attr exists in dataset                                                                                                                                                                                                                                                                                                                                |
| coerceDataset:{}                                               | replaces or suplements attrs in dataset                                                                                                                                                                                                                                                                                                                       |
| replaceInDataset:{}                                            | only if attr already existed in dataset                                                                                                                                                                                                                                                                                                                       |
| supplementToDataset:{}                                         | only if attr did not exist in dataset                                                                                                                                                                                                                                                                                                                         |
| removeFromEUIDprefixedDataset:{ "UIDprefix":[atributeID]}      | EUIDprefixed permite seleccionar estudios para los cuales se usó EUID de la MWL. Performed last (may undo a previous coercion)                                                                                                                                                                                                                                |
| j2kLayers:                                                     | (num) 0=natv (native sin compresión), 1=j2kr (1 fragmento), 4=bfhi (j2kr with four quality layers (base/fast/hres/idem))                                                                                                                                                                                                                                      |
| sourceAET:                                                     | AET branch origen (0002,0016)                                                                                                                                                                                                                                                                                                                                 |
| receivingAET:                                                  | AET destino (0002,0018)                                                                                                                                                                                                                                                                                                                                       |
| storeMode:                                                     | DICMhttp1,DICMhttp2,DICMhttp3,-xv,-xs,-xe,-xi                                                                                                                                                                                                                                                                                                                 |
