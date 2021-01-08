Transformative pipeline
=======================

(X) dataset contextualized key-values xml es el formato preferido como resultado de parseo, porque permite validación por schema xml y modificaciones por script xsl.

Se crearon dos aplicaciones para parsear el binario desde (D) dataset dicom binario y (H) dataset dicom binario hexa (1 octet ASCII 0-0A-F para cada grupo de 4 bytes). En caso que el binario DICOM este codificado además en base64 o zipeado, se antepone el decodificador correspondiente en la linea de comandos.
 
El parseador incluye el opción de aplicar una transformación xsl 1 al xml antes de finalizarse. El xsl permite otros outputs derivados:
- (B) dataset contextualized key-values bson
- (G) dataset dicom json
- (J) dataset contextualized key-values json (ready for serialization)
- (K) dataset dicom native xml

Escribimos una transformación xsl1 que permite volver a X desde K. Para aplicarla dentro de un contexto serializado (sin escritura a disco), se puede usar la herramienta X2X. Se puede aplicar esta aplicación para la aplicación de cualquier xsl 1.

(B) es similar a (X) salvo que está escrito en BSON en lugar de XML. Sigue conteniendo los atributos DICOM ordenados gracias a keys contextualizadas, pero es mucho más compacto, en un formato que se parece a un JSON extendido escrito en binario. B:
- puede almacenarse en base de datos mongodb
- está optimizado para una rápida serialización en dicom binario.

