# opendicom/cstoredicom/install.sh

cstoredicom envia por dicom c-store series de objetos dicom encontrados dentro de la carpeta de destino.

Para instalarlo ejecutar opendicom/cstoredicom/install.sh con parametros:

- admin
- org
- org DICOMweb store endpoint
- org DICOMweb qido endpoints
- timeout

Ejemplo:

```sh
/Users/Shared/opendicom/storedicom/install.sh pcs2 DCM4CHEE "https://serviciosridi.asse.uy/dcm4chee-arc/stow/DCM4CHEE" "https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE" 120
```

Crea:

- /Volumes/IN/[org] y contenido
- /Users/Shared/opendicom/storedicom/[org]  y contenido
- /Users/[admin]/Library/LaunchAgents/storedicom.[org].plist
- /Users/[admin]/Library/LaunchAgents/recycleMismatchService.[org].plist
