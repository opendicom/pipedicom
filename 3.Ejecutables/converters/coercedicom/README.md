coercedicom
===========

Procesa los directorios y archivos DICOM encontrados en subdirectorios de un directorio Spool.


## RECEIVED

RECEIVED es el contenedor de todas las nuevas imágenes, clasificadas en una estructura a tres niveles:

- SOURCE: La primera subdivisión indica el origen de dónde viene la imagen. Por ejemplo: la carpeta llamada "CR@NXGENRAD@192.168.4.16" indica que la imagen de modalidad radiografía directa (CR) fue enviada desde un equipo identificado por el AET "NXGENRAD" desde el IP local "192.168.4.16". Todas las subcarpetas de "CR@NXGENRAD@192.168.4.16" contienen archivos proveniente del mismo origen.

- STUDY: La segunda subdivisión está constituida por carpetas con el identificador único de un estudio (EUID) como nombre.

- instance: El tercer nivel, o sea dentro de una carpeta de estudio, son las imágenes que correspondena este estudio, identificadas por su SOPUID.


| RECEIVED   |
| ---------- |
| [SOURCE]   |
| [STUDY]    |
| [instance] |


El procesamiento se realiza en base a las directivas que se encuentran en coercedicom.json.

```
[
    {
        "regex":".*",
        "coerceDataset":{
           "00000001_00080080-1100LO" :[ "DCM4CHEE" ]
        },
        "storeBucketSize":3450000
    },
    {
        ...
    }
]
```

Coercedicom.json es un array de objetos. Cada uno de ellos contiene un regex que permite matchear la  [SOURCE] de las imágenes recibidas. Las directivas incluidas en el objeto aplican a los estudios provenientes de las [SOURCE] que satisfacen el regex.



## MISMATCH_SOURCE, MISMATCH_CDAMWL, MISMATCH_PACS

Cuando aparece un SOURCE que no satisface ningún regex, coercedicom lo mueve a un subdirectorio del  directorio MISMATCH_SOURCE. 

Cuando coercedicom está acoplado a cdamwl, un estudio que demuestra incompatibilidades con el item de MWL correspondiente va a MISMATCH_CDAMWL.

Lo mismo cuando coercedicom está configurado para verificar los datos patronímicos con un pacs de destino, pero esta vez los estudios que generan ambiguëdad a nivel de la identificación del paciente están apartados dentro  de un directorio MISMATCH_PACS


 SOURCE nuevo

| RECEIVED   | MISMATCH_SOURCE |
| ---------- | --------------- |
| [SOURCE]-> | [SOURCE]        |



  Otro estudio de un  SOURCE ya descartado o descartado luego de otras verificaciones

| RECEIVED  | MISMATCH_SOURCE  \| MISMATCH_CDAMWL \|  MISMATCH_PACS |
| --------- | ----------------------------------------------------- |
| SOURCE_1  | SOURCE_1                                              |
| [STUDY]-> | [STUDY]                                               |



  Otra instancia de un estudio ya descartado

| SPOOL     | MISMATCH_SOURCE  \| MISMATCH_CDAMWL \| MISMATCH_PACS |
| --------- | ---------------------------------------------------- |
| SOURCE_1  | SOURCE_1                                             |
| STUDY_1   | STUDY_1                                              |
| [image]-> | [image]                                              |



 Instancia repetida de un estudio ya descartado

| SPOOL     | MISMATCH_SOURCE  \|  MISMATCH_CDAMWL \|  MISMATCH_PACS |
| --------- | ------------------------------------------------------ |
| SOURCE_1  | SOURCE_1                                               |
| STUDY_1   | STUDY_1                                                |
|           | IMAGE_1                                                |
|           | 1.dcm                                                  |
| image_1-> | 2.dcm                                                  |

En caso de imagen repetida, se cree un directorio para todas las instancias.
Este tipo de traslado no destruye datos recibidos y construye un historial de lo recibido.



## ORIGINALS y FAILURE

Cuando aparece una imagen de un SOURCE válido, se realizan las operaciones de coerción correspondientes, que tienen por resultado la creación de una nueva imagen, en caso que las operaciones fuesen exitosas. Luego de las operaciones, el original sin modificar está trasladado a una de las carpetas ORIGINALS (si la operación fue exitosa) o FAILURE (si no se pudo crear la nueva imagen).


Otra instancia de un estudio

| RECEIVED  | ORIGINALS / FAILURE |
| --------- | ------------------- |
| SOURCE_1  | SOURCE_1            |
| STUDY_1   | STUDY_1             |
| [image]-> | [image]             |



Instancia repetida

| RECEIVED  | ORIGINALS / FAILURE |
| --------- | ------------------- |
| SOURCE_1  | SOURCE_1            |
| STUDY_1   | STUDY_1             |
|           | IMAGE_1             |
|           | 1.dcm               |
| image_1-> | 2.dcm               |






## SEND

Un subdirectorio de SUCCESS recibe las imágenes creadas como resultado de la coerción.
En esta ocasión aparecen dos niveles de subcarpetas adicionales, ORG y BUCKET

| SEND       |
| ---------- |
| [ORG]      |
| [SOURCE]   |
| [STUDY]    |
| [BUCKET]   |
| [instance] |

- ORG indica el AET de la institución de referencia de las imágenes en el PACS central. Por ejemplo asseMALDONADO.
- BUCKET subdivide el estudio en grupos de archivos que en total no superan cierto tamaño y pueden ser objeto de un envío por lote sin superar el limite definido en el servidor para los POST. Dentro de bucket, los archivos DICOM tienen un prefijo http y se agrega al conjunto un archivo http tail que facilita la construcción de un POST http multipart/related


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

enum CDargName{

   CDargCmd,

   CDargSpool,
   CDargSuccess,
   CDargFailure,
   CDargOriginals,
   CDargSourceMismatch,
   CDargCdawlMismatch,
   CDargPacsMismatch,

   CDargcoercedicom,            //archivo de configuración de las coerciones
   CDargCdamwlDir,               //cdawldicom dir path (if empty, no test2)
   CDargPacsSearch,             //DICOMweb search url (if empty, no test3)

   CDargAsyncMonitorLoopsWait   // nxms (n=loops number, m=seconds wait) m=0 -> proceso sincrónico
};


# Archivo de configuración coercedicom.json
