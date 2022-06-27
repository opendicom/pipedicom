# dcmtk/storescp/install.sh

storescp recibe objetos DICOM enviados por equipos imagenológicos y los clasifica por origen y estudio.

Para instalarlo, ejecutar dcmtk/storescp/install.sh con sudo y parametros:

- pcs aet
- pcs port
- admin user name

Ejemplo:

```sh
sudo /Users/Shared/dcmtk/storescp/install.sh asseSAINTBOIS 4096 pcs2
```

El usuario root dispara storescp. Aplicamos un cambio de propietario sobre los objetos DICOM recibidos para que sean accesibles por un usuario admin. En ASSE este usuario es "pcs2"

Crea:

- /Volumes/IN/[pcs aet]   y contenido
- /Users/Shared/dcmtk/storescp/[pcs aet]  y contenido
- /Library/LaunchDaemons/storescp.[pcs aet].[pcs puerto].plist
