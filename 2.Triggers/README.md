# Trigger (linux)

## Escrutinio de nuevo archivo

Cron, con su inicio repetido de tareas, permite definir la frecuencia del escrutinio.

La sintaxis 
```
m * * * * comando
```
define en que minuto m de cada hora se inicia el comando que sigue.

Para repetir la tarea más de una vez cada hora, se puede duplicar la linea con un m diferente en cada copia.

### Ejemplo

```
10 * * * * find `date "+/RAID5_sd4/DICOM/\%-Y/\%-m/\%-d/0"` -type f -perm 644 -exec chmod 464 {} \;
40 * * * * find `date "+/RAID5_sd4/DICOM/\%-Y/\%-m/\%-d/0"` -type f -perm 644 -exec chmod 464 {} \;

8 * * * * find `date "+/RAID5_sd4/DICOM/\%-Y/\%-m/\%-d/0"` -type f -perm 464 -exec /opt/dcm4che-2.0.24/bin/sr2img.sh {} \;
38 * * * * find `date "+/RAID5_sd4/DICOM/\%-Y/\%-m/\%-d/0"` -type f -perm 464 -exec /opt/dcm4che-2.0.24/bin/sr2img.sh {} \;

```
En este ejemplo, programamos dos comandos en un ciclo alternativo cada media hora.
El propósito de esta configuración es de iniciar una action sobre un archivo luego de 29 a 58 minutos de su creación. 

Usamos el comando find para encontrar los archivos. Usamos una modificación de permisos de los archivos para filtrar los archivos seleccionados:

- -rw-r--r-- (644) es el permiso original de un nuevo archivo
- -r--rw-r-- (464) apenas detectado se cambia su permiso de tal forma que NO aparezca nuevamente en el filtro que busca nuevos archivos. Un scrutinio por archivos con permiso 464 encuentra los que se había etiquetados y aplica un comando a ellos. El comando incluye un nuevo cambio de permisos, para que el archivo NO vuelva a aparecer en el scrutinio y NO se vuelva a aplicar el comando a este archivo otra vez (veces)
- -r--r-xr-- (454) permiso atribuido a archivos que ya fueron procesados y escaparán al scrutinio para nuevos archivos y para archivos a procesar.

| creación | descubrimiento | procesamiento | latencia |
|--|--|--|--|
| 10-39 | 40 | 68 | 29-58 |
| 40-09 | 10 | 38 | 29-58 |




