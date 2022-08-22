# opendicom/storedicom/install.sh

storedicom envia por dicom store series de objetos dicom encontrados dentro de la carpeta de destino.

Para instalarlo ejecutar opendicom/storedicom/install.sh con sudo y parametros:

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
- /Users/pcs2/Library/LaunchAgents/storedicom.[org].plist
- /Users/pcs2/Library/LaunchAgents/recycleMismatchService.[org].plist
- /Users/pcs2/Library/LaunchAgents/cleanReferenced.[org].plist

