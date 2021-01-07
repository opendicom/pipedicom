Transformative pipeline
=======================

(X) dataset contextualized key-values xml es el formato preferido.

Desde (D) dataset dicom binario y (H) dataset dicom binario hexa (1 octet ASCII 0-0A-F para cada grupo de 4 bytes) se crearon dos aplicaciones para parsear el binario correspondiente. En caso que el binario DICOM este codificado además en base64 o zipeado, se antepone el decodificador en la linea de comandos.
 
El parseador incluye el opción de aplicar una transformación xsl 1 al xml antes de finalizarse. El xsl permite otros outputs derivados:
- (B) dataset contextualized key-values bson
- (G) dataset dicom json
- (J) dataset contextualized key-values json
- (K) dataset dicom native xml
- (M) dataset contextualized key-values json marshalled (ready for serialization)

Desde K escribimos una transformación xsl 1 que permite volver a X. para aplicarla dentro de un contexto serializado sin escritura a disco, se puede usar la herramienta X2X. Se puede aplicar esta aplicación para la aplicación de cualquier xsl 1.

El camino inverso desde X hacia B (X2B), se realiza en dos etapas:
- la primera transforma X en M mediante un xsl 1. M difiere de X porque agrega en forma sistematica un atributo para cada apertura de item y cierre de item y secuencia. Además preconcatena los valores de tipo textual.
- la segunda traduce consecutivamente los atributos de M (ya perfectamente ordenados) en binario. Es una serie de operaciones atomicas que pueden realizarse en paralelo, antes de juntarlas en el orden predefinido.
