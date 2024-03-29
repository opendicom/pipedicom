# 3.Ejecutables

Cada ejecutable cumple una acción entre input y output.

## Usan los terminales de la siguiente forma:

- stdin lee el input stream
- stdout escribe el output stream
- el nombre del ejecutable se usa para llamarlo
- cada ejecutable puede definir sus propios parametros obligatorios o opcionales que se escriben a continuación del nombre del ejecutable
- Variables de entorno XlogLevel, XlogPath y XtestPath prefijadas con el nombre del ejecutable X Facilitan la auditoria y el debugging de los ejecutables

## Nombre de los ejecutables
El nombre de los ejecutables empieza con dos mayusculas. La primera indica el tipo de input y la segunda el tipo de output

Lista de los tipos de input y output con datos:
-    (A) dataset dicom (B, D, G, H, J, M o N)
-    (B) dataset contextualized key-values bson (ready for serialization)
-    (D) dataset dicom binario
-    (G) dataset dicom json
-    (H) dataset dicom binario hexa (1 octet ASCII 0-0A-F para cada grupo de 4 bytes)
-    (J) dataset contextualized key-values json (ready for serialization)
-    (M) dataset contextualized key-values xml map (ready for serialization)
-    (N) dataset native dicom xml

Lista de los tipos de input y output identificadores:
-    (O) identificador de un objeto de una tabla de base de datos (I, S, o E)
-    (I) SOPInstanceUID del objeto
-    (S) SeriesInstanceUID de la serie
-    (E) StudyInstanceUID del estudio

Lista de los tipos de input y output con rutas y urls:
-    (R) Ruta en sistema de archivo a archivo dicom (B, D, G, H, J, K o X)
-    (U) url a stream dicom (B, D, G, H, J, M o N)
-    (W) url wado dicom binario
-    (V) url de visualización (siempre final de una cadena)
