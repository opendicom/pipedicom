

PCS2 install
===========

Versión 2.4

PCS2 incluye 5 servicios principales:

- **dcmtk/storescp** (recepción imágenes)
- **dcmtk/wlmscpfs** (publicación worklist)
- **opendicom/coercedicom** (coerción + compresión j2kr imágenes)
- **opendicom/storedicom** (reenvio imágenes)
- **opendicom/cdamwldicom** (creación items worklist)

Cada uno de ellos incluye procesos accesorios para limieza de los temporales.



Además, PCS2 ofrece servicios opcionales:

- **opendicom/qwprefetch** (qido/wado prefetch)

- **opendicom/cstoredicom** (manda series encontradas en el sistema de archivo por DICOM C-STORE)

  

Cada uno de estos 7 servicios puede estar publicado varias veces (para pipelines distintos)



## Prerequisitos

- dcmtk 3.6.7  opendicom modified branch installed
- opendicom pipedicom installed



## Location

Configuración y administración de los servicios se encuentran en **/Users/Shared/**

- **dcmtk** contiene los archivos relativos a storescp y a wlmscpfs
- **opendicom** contiene los archivos relativos a coercedicom, storedicom y cdamwldicom
- **pass.sh** permite automatizar sudo
- **start_all.sh** distribuye el orden de iniciar cada servicio instalado
- **stop_all.sh** distribuye el orden de parar cada servicio instalado
