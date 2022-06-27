# opendicom/storedicom/install.sh

storedicom envia por dicom store los paquetes de objetos dicom dentro de la carpeta de destino.

Para instalarlo ejecutar opendicom/storedicom/install.sh con sudo y parametros:

- org
- url
- log

Ejemplo:

```sh
sudo /Users/Shared/opendicom/storedicom/install.sh DCM4CHEE "https://serviciosridi.asse.uy/dcm4chee-arc/stow/DCM4CHEE/studies" CURL_SILENT
```

Crea:

- /Volumes/IN/[org] y contenido
- /Users/Shared/opendicom/storedicom/[aet]  y contenido
- /Users/pcs2/Library/LaunchAgents/storedicom.[org].plist
- /Users/pcs2/Documents/opendicom/storedicom.[org].log
- /Users/pcs2/Documents/opendicom/storedicom.[org].error.log
