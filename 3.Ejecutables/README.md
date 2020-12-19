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
-    (A) dicom (cualquier representación D, B, H, X, J o P)
-    (B) dicom binario base64
-    (D) dicom binario
-    (H) dicom binario hexa (1 octet ASCII 0-0A-F para cada grupo de 4 bytes)
-    (I) dicom xml
-    (J) dicom json
-    (P) plist ( [[headstrings],[bodystrings],[headdatas],[bodydatas]] )
-    (X) opendicom xml
-    (O) identificador de un objeto de una tabla de base de datos
-    (I) SOPInstanceUID del objeto
-    (S) SeriesInstanceUID de la serie
-    (E) StudyInstanceUID del estudio
-    (R) Ruta a archivo dicom (cualquier representación D, B, H, X, J o P)
-    (U) ur la stream dicom (cualquier representación D, B, H, X, J o P), sin precisión del contenido
-    (W) url wado dicom binario
-    (V) url de visualización (siempre final de una cadena)