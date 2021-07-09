coercedicom
===========

Procesa los directorios y archivos DICOM encontrados en subdirectorios de un directorio Spool.

Arguments
-------------
enum CDargName{
   CDargCmd,
   CDargSpool,
   CDargSuccess,
   CDargFailure,
   CDargDone,
   CDargInstitutionmapping,          //mapping  sender -> org
   CDargCdamwlDir,                       //cdawldicom matching
   CDargPacsquery,                        //pacs for verification
   CDargAsyncMonitorLoopsWait   // nxms (n=loops number, m=seconds wait)
};

Estructura de subdirectorios
------------------------------
Spool es el contenedor de todas las nuevas entradas. Adentro, las imágenes están clasificadas en una estructura a tres niveles:
- (source) La primera subdivisión indica el origen de dónde viene la imagen. Por ejemplo: la carpeta llamada "CR@NXGENRAD@192.168.4.16" indica que la imagen de modalidad radiografía directa (CR) fue enviada desde un equipo identificado por el AET "NXGENRAD" desde el IP local "192.168.4.16". Todas las subcarpetas de "CR@NXGENRAD@192.168.4.16" contienen archivos proveniente del mismo origen.
- (study) La segunda subdivisión está constituida por carpetas con el identificador único de un estudio (EUID) como nombre.
- (instance) El tercer nivel, o sea dentro de una carpeta de estudio, son las imágenes que correspondena este estudio, identificadas por su SOPInstanceUID.

Done es el destino de un mv de las subdirectorios de los originales procesados exitosamente

En caso que hubo falla de procesamiento, se realiza un mv las subdirectorios de los originales a una subcarpeta de Failure

El resultado del procesamiento se escribe dentro de Success. Un primer nivel de subdirectorios refleja la org de destino. Los siguientes niveles de subdirectorios reflejan la estructura dentro de Spool

Tests
------
coercedicom aplica :
- (test1) fuente de la información (source) conocida, 
- (test2)  compatibilidad de (study) con los items de mwl (presupone  test1 exitoso)
- (test3) compatibilidad de (study) con los datos existentes en el pacs (presupone  test2 exitoso)

Dependiendo de los resultados:

- Si (test1) falla, la carpeta (source) está movida al subdirectorio DISCARDED.
- Si (test2) o (test3) falla, la carpeta (study) está movida a un directorio creado en base al nombre del error encontrado.
- Si los tests son exitosos, los archivos (instance) están procesados.
- Si el proceso es exitoso, el resultado del procesamiento está colocado dentro del directorio COERCED (repitiendo la misma subestructura de carpetas que dentro del directorio CLASSIFIED). Los originales (antes procesamiento) están  desplazados a un subdirectorio ORIGINALS de RECEIVER (repitiendo la misma subestructura que dentro del directorio CLASSIFIED).
- Si el proceso fracasó,  los originales (antes procesamiento) están  desplazados a un directorio creado en base al nombre del error encontrado dentro de RECEIVER.


(test1) source
---------------
La primera subdivisión contiene información suficiente para comparar con una lista blanca de los equipos autorizados a mandar estudios. 

La lista blanca es un archivo json conteniendo un solo objeto que relaciona "patterns" de expresiones regulares con nombres de organización. El "pattern" más básico es el titulo de la subcarpeta de origen tal cual como aparece en la carpeta CLASSIFIED. Por ejemplo, el pattern "CR@NXGENRAD@192.168.4.16" valida el origen de imágenes que provienen de un equipo de rayos X llamado "NXGENRAD" con IP "192.168.4.16".

Un estudio que llegue dentro de una carpeta origen que no verifica ningún filtro regex de la lista blanca está desplazado al directorio REJECTED

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
                   /symlink EUID -> EUID      
              /PID     
                 /patientID[^issuer]
                   /symlink EUID -> EUID        
 ```

Toda esta información accesible localmente permite realizar multiples tests, que se hubiese usado la lista de trabajo desde la modalidad de imagenología o no.

- (2.1) Buscar correspondencia entre las imágenes producidas y una tarea de la lista. La primera opción es mediante el StudyInstanceUID, que es estructurante de ambos sistemas de archivos para cdawldicom y coercedicom. 
- (2.2.1) La segunda opción es el accessionNumber. Requiere parseo del archivo
- (2.2.2)  La tercera el identificador de paciente. El parseo sirve también para este caso.
Si la búsqueda no dió resultados, se considera que el estudio es independiente de la cdawldicom y se cierra el segundo capitulo de test. 

- (2.3) Verificación que las informaciones paciente son similares. Si existen diferencias, alertar y colocar en una subcarpeta del directorio REJECT. Sino realizar la coerción, usando cdawldicom a este efecto.

(test3) Consulta al pacs de destino
-------------------------------
(no instrumentado en ASSE)
