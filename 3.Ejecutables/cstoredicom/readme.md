# CSTOREDICOM

CSTOREDICOM pertenece a un grupo de aplicaciones especializadas útiles para construir un proxy DICOM. El grupo incluye funciones de recepción, procesamiento y envío.



### Funciones

- lee periodicamente el contenido de un directorio buffer INPUT de entradas estructuradas

- encuentra cada sub directorios "series" de los cuales el contenido no fue modificado desde más de 30 segundos

- manda el contenido de los sub directorios "series" a un PACS por protocolo DICOM C-STORE usando dcmtk storescu

  - cuando el PACS contesta que el envío fue exitoso, CSTOREDICOM mueva el subdirectorio a un directorio OUTPUT, replicando la estructura del directorio INPUT
  - cuando el PACS contesta que el envío fue problemático, CSTOREDICOM mueva el subdirectorio a un directorio ERROR, replicando la estructura del directorio INPUT

  

### Estructura de INPUT, OUTPUT, ERROR

INPUT

​			SOURCE

​						STUDY

​									SERIES

​												INSTANCE.dcm		



### Integración 

- STORESCP > CSTOREDICOM
- CSTOREDICOM > CSTOREDICOM
- CSTOREDICOM > COERCEDICOM