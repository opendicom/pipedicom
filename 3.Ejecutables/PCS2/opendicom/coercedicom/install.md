# opendicom/coercedicom/install.sh

coercedicom verifica, comprime y aplica coerción sobre objetos dicom de un directorio spool y crea el resultado dentro de un directorio de destino.

Para instalarlo:

Requiere que dcmtk/storescp correspondiente ya fuese instalado.
Luego, ejecutar opendicom/coercedicom/install.sh con sudo y parametros:

- pcs aet
- pacs aet
- user admin name


Ejemplo:

```sh
sudo /Users/Shared/opendicom/coercedicom/install.sh asseSAINTBOIS DCM4CHEE pcs2
```

Crea:

- /Users/Shared/opendicom/coercedicom/[pcs aet]  y contenido
- /Users/pcs2/Library/Launchagents/coercedicom.[pcs aet].plist
