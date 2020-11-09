# Find script trigger

Varias partes de este script find de ejemplo son más fáciles de entender acompañadas de un comentario.

Indicamos en la columna izquierda los nros de linea de script que se comentan en la segunda columna. El script se encuentra en el presente directorio.


| lineas | comentario |
|--|--|
| 12 | el script usa ejecutables de la caja de herramientas dcm4chee2. Ajustamos en directorio base en consecuencia. Existen otra formas de resolver eso sin depender de la ubicación de la caja de herramientas |
| 15-16 | En caso que se guardó el original y enseguida una copia corregida, queremos exportar exclusivamente el más reciente. Para eso, listamos del más nuevo al más viejo el contenido del directorio y seleccionamos exclusivamente la primera linea. No olvidar de deshabilitar también el archivo omitido al final del proceso (ver lineas 80-82) | 
| 19 ...  | `echo >> /var/log/sr2img.log` no sale por stdout|
| 24 ... | `=$( echo` entra una linea al pipe que sigue para logra un resultado conservado en la variable |
| 69 | `echo ... >> /dev/null` echo entra una linea al pipe e intercepta el output para silenciarlo |
| 72 | sleep 1 deja un segundo pasar un segundo antes de consultar la base de datos del pacs dónde el archivo fue mandado... para evitar potenciales problemas de sincronización |

## ¿Porqué no terminamos el script con un echo de output?

Porqué en las lineas 84-89 creamos dos nuevos directorios spool que son objetos de escrutinio independiente. 
