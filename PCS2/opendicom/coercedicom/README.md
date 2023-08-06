# coercedicom



# cleandevice.sh

DICOMweb stow, por lo menos en conjunto con dcm4chee-arc es un protocolo que no garantiza que todos los objetos lleguen siempre. El servicio puede no ser disponible, El servidor puede limitar la cantidad de datos recibidos en un POST, una red lenta puede provocar un timeout. El proceso de envio storedicom permite gestionar estos casos. Pero al final borra los objetos que fueron enviados exitosamente. La auditoria se escribe mediante archivos de log en Documents. Este dispositivo no recuperación de desastre. Para eso, los archivos originales (antes cualquier coerción o compresión) están guardados dentro del PCS durante un tiempo prudencial.

**cleandevice.sh** función es eliminar los objetos de este repositorio transitorio luego de un tiempo prudencial y luego de verificación que los objetos esten almacenados den el pacs.

## Uso

- requiere que los objetos DICOM tengan com nombre el SOP instance UID con extensión '.dcm' y estén agrupados en directorios series de los cuales el nombre es el Serie Instance UID

- el URL de DICOMweb es estático en el código. Modificar según necesidades

- Ir al directorio device con cd

- ejecutar cleandevice.sh con eventuales argumentos complementarios para el comando find

## Log

- NOT IN PACS ./study/series

- REMOVE instancesNumber ./study/series

- ./study/series
  
  - R/L     instancesNumberRemote    instancesNumberLocal
  
  - linea dónde cada instancia local está representada por :
    
    - `o` (si existe solo localmente)
    
    - `-`(si existe también remotamente, en cual caso se borra localmente)
    
    - `·`(si existe también remotamente, pero no se puede borrar localmente)




