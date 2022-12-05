# CSTOREDICOM

CSTOREDICOM pertenece a un grupo de aplicaciones especializadas útiles para construir un proxy DICOM. El grupo incluye funciones de recepción, procesamiento y envío.

### Funciones

- lee periodicamente el contenido de un directorio buffer SEND de entradas estructuradas

- encuentra cada sub directorios "series" de los cuales el contenido no fue modificado desde más de 30 segundos

- manda el contenido de los sub directorios "series" a un PACS por protocolo DICOM C-STORE usando dcmtk storescu
  
  - cuando el PACS contesta que el envío fue exitoso, CSTOREDICOM mueve el subdirectorio a un directorio SENT, replicando la estructura del directorio SEND
  - cuando el PACS contesta que el envío fue problemático, CSTOREDICOM mueve el subdirectorio a un directorio WARN, replicando la estructura del directorio SEND

### Estructura de INPUT, OUTPUT, ERROR

SEND

​            SOURCE

​                        STUDY

​                                    SERIES

​                                                INSTANCE.dcm        

### Integración

- STORESCP > CSTOREDICOM
- CSTOREDICOM > CSTOREDICOM
- CSTOREDICOM > COERCEDICOM



### Parametros

SEND (path)

SENT (path)

WARN (path)

AET (sending)

AEC (receiving)

IP (receiving)

PORT (receiving)

TS (tranfer syntax, as declared in dcmtk -xv, -xe, ...)