# cdawldicom

Alternativa flexible para la publicación de una  Modality worklist DICOM . Las solicitudes se archivan como objetos Dicom encapsulated CDA modalidad OT dentro de un pacs DICOMweb central. Peticiones DICOMweb permiten encontrar las solicitudes que corresponden al servicio de imagenología y transformarlas en  worklist items (.wl) DICOM publicadas por un servidor dcmtk wlmspcfs local para consumo por las modalidades DICOM de imagenología.

## ¿Porqué una alternativa a la mensajería hl7 v2?
- La solicitud en formato CDA es un formato de archivo muy superior a hl7v2, tiene válidez legal y una modelización de la información sin las limitaciones de hl7 v2
- La solicitud puede ser usada como base que no requiere traducción de formato para el informe DICOM CDA
- Permite la integración de adjuntos (hoja de presentación xslt1, documentos pdf, etc)
- La solicitud queda naturalmente adjunta a las imágenes subsecuentes del estudio
- El uso de DICOMweb simplifica la configuración para cualquier situación de red

## Esquema de distribución

RIS central   <-   PACS DICOMweb central   <-wlmscp local   <-   Modalidad imagenológica DICOM

RIS central (Radiology Information System): Servidor que publica formularios electrónicos y colecta las informaciones necesarías a la creación de solicitudes de cita de imagenología médica. El formato de las solicitudes es un CDA encapsulado dentro de un objeto DICOM. Dicho objeto se manda al PACS central.

PACS DICOMweb central: un PACS DICOMweb es accesible por http rest en particular para buscar objetos y pedir copia de los mismos.

wlmscp local: Repetidor de requests al PACS DICOMweb central para obtener nuevas solicitudes y transformarlas en worklist items publicados por un servidor wlmscp local para su consumo por las modalidades de imagenología local.

## Sistema de archvivos de cdawldicom/audit

``` 
/published/scpaet/EUID.wl
/consumed/scpaet/EUID.wl
/matched/scpaet/EUID.wl
/unused/scpaet/EUID.wl

/aaaammdd
        /StudyInstanceUID
                /cda.xml
                /wl.json
        /accessionNumber[^issuer]
                /symlink StudyInstanceUID -> StudyInstanceUID        
        /patientID[^issuer]
                /symlink StudyInstanceUID -> StudyInstanceUID        
```

## Uso en conjunto con coercedicom

Coercedicom es otro producto que permite validar y normalizar objetos imagenológicos DICOM antes de su envío a un PACS central. En la etapa de validación, coercedicom puede validar localmente con la información almacenada en el sistema de archivos de cdawldicom. Adicionalmente, si la Modality WorkList no fue usada en el equipo imagenológico pero la información demográfica y de cita entrada es lo suficientemente similar a la que está registrada en cdawldicom para una solicitud, coercedicom puede realizar la coerción correspondiente para normalizar las imágenes.
