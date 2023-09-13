# Dockerpacs + coercedicom dcmsnd -fileref

El prototipo de esta instalación se encuentra en IRP, que consta con un servidor MAC, otro LINUX con un SSD online y una conexión samba a un NAS nearline

- LINUX contiene DOCKERPACS
  
  - docker-compose.yml mapea volumes entre el contenedor y el sistema, y en particular mapea SSD y NAS

- MAC
  
  - tiene SSD de LINUX montado por Samba
  
  - corre coercedicom que escribe en SSD
  
  - corre dcmsnd -fileref, que usa el path en SSD para referenciar con ruta no relativa (empezando con /) los archivos dentro de la base de datos de DOCKERPACS de LINUX

dcm4che-2.0.29 dcmsnd -fileref permite mandar todos los atributos  DICOM excepto los pixeles, y comunicar al pacs dcm4chee-2.18.3 la ubicación del archivo DICOM completo, incluyendo los pixeles.

Optimizamos la comunicación entre coercedicom storemode cesiB64 y dcm4chee-2.18.3 en que coercedicom escribe directamente el archivo dicom en el archive de dcm4chee-2.18.3, y luego entrega a dcm4chee-2.18.3 la metadata necesaria para indexar el archivo DICOM.

Este modo de proceder ahorra escritura. El resultado de la compresión se escribe una sola vez.

Este modo de proceder ahorra memoria de procesamiento de objetos en el pacs, porque maneja los pixeles por referencia.

El storemode cesiB64 es una formalización de ruta con segmentos:

- c : cronologico (fecha de estudio aammdd)

- e : studyiuid

- s : seriesiuid

- i : sopiuid

Todos los segmentos están comprimidos con una codificación base64 con optimización especial propietaria, que tiene la particularidad de conservar las clasificaciones alfanumericas de los comprimido iguales a las de lo no comprimido. 

## dcmsnd

La ruta canonica para dcmsnd es /Users/Shared/dcm4che-2.0.29/bin/dcmsnd.

Es prerequisito que este instalado así como java correspondiente.

Ejemplo de invocación:

```
/Users/Shared/dcm4che-2.0.29/bin/dcmsnd -fileref -L IRP-PROV IRP@172.16.0.3:11112 /Volumes/SSD1/IRP/IRP-PROV/TIxK/UMMQkMKSDP4l
```

# Objectivo

La ruta usada por dcmsnd en MAC tiene que ser la misma que luego usa DOCKERPACS

## MAC /Volumes

MAC (macos 10,15) tiene la particularidad de separar el disco principal en dos particiones:

- / de sistema operativo, que contiene exclusivamente software apple y es read only

- /Volumes, que permite acceder a cualquier otro volumen montado, donde se puede escribir y leer.

Eso implica que en MAC, la ruta no relativa empieza con /Volumes.

Para indicar que se accede a un SSD local (o sea ONLINE enDOCKERPACS), la ruta podría empezar con /Volumes/SSD1.

Además, especificamente para IRP definiriamos tres rutas :

- /Volumes/SSD1/IRP/IRP-PROV

- /Volumes/SSD1/IRP/IRP-LH

- /Volumes/SSD1/IRP/IRP-BB

Para lograr eso LINUX tiene que montar el SSD como /Volumes/SSD1

## SSD ONLINE en LINUX

El SSD está actualmente montado como /DICOM en LINUX.

Tendría que estar montado en /Volumes, como /Volumes/SSD1

/Volumes ya existe y contiene pacsnas (NAS NEARLINE)

No olvidarse de modificar la publicación SAMBA !!!!

## SSD desde DOCKERPACS

docker-compose.yml contiene una sección de mapeo de mount points.

Volumes:

- /DICOM/IRP:/DICOM/IRP/

Tendría que reemplazarse por

- /Volumes/SSD1/IRP:/Volumes/SSD1/IRP/

Así para dcm4chee, la ruta de acceso al archivo es exactamente a la ruta que se usó en dcmsnd -fileref

## DCM4CHEE configuración

Cambiar en la tabla filesystem de pacsdb /DICOM/IRP por /Volumes/SSD1/IRP
