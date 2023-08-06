# opendicom/coercedicom/install.sh

coercedicom verifica, comprime y aplica coerción sobre objetos dicom de un directorio spool y crea el resultado dentro de un directorio de destino.

Para instalarlo:

Requiere dcmtk y pipedicom instalados.
Luego, ejecutar opendicom/coercedicom/install.sh con sudo y parametros:

- admin
- org
- branch


Ejemplo:

```sh
sudo /Users/Shared/opendicom/coercedicom/install.sh pcs2 DCM4CHEE asseSAINTBOIS
```

Crea:

- /Users/Shared/opendicom/coercedicom/[branch]  y contenido
- /Users/[admin]/Library/Launchagents/coercedicom.[branch].plist
- /Users/[admin]/Library/Launchagents/cleanOriginals.[branch].plist
