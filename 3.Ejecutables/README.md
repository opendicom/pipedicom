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

Lista de los tipos de input y output:
-    (A) dataset dicom (cualquier representación D, B, H, I, J, X o P)
-    (B) dataset dicom binario base64
-    (D) dataset dicom binario
-    (H) dataset dicom binario hexa (1 octet ASCII 0-0A-F para cada grupo de 4 bytes)
-    (I) dataset dicom json
-    (J) dataset contextualized key-values json
-    (M) dataset contextualized key-values json marshalled (ready for serialization)
-    (K) dataset dicom xml
-    (P) dataset plist ( [[headstrings],[bodystrings],[headdatas],[bodydatas]] )
-    (X) dataset contextual key-values xml
-    (O) identificador de un objeto de una tabla de base de datos
-    (I) SOPInstanceUID del objeto
-    (S) SeriesInstanceUID de la serie
-    (E) StudyInstanceUID del estudio
-    (R) Ruta en sistema de archivo a archivo dicom (cualquier representación D, B, H, I, J, X o P)
-    (U) url a stream dicom (cualquier representación D, B, H, I, J, X P, W, V), sin precisión del contenido
-    (W) url wado dicom binario
-    (V) url de visualización (siempre final de una cadena)
