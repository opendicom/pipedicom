# dcmtk/wlmscpfs/install.sh

wlmscpfs publica items de worklist para el consumo por parte de los equipos imagenológicos. Para instalarlo, ejecutar dcmtk/wlmscpfs/install.sh con sudo y parametros:

- admin
- branch
- puerto
- pacs

Ejemplo:

```sh
sudo /Users/Shared/dcmtk/wlmscpfs/install.sh pcs2 asseSAINTBOIS 11112 DCM4CHEE
```

 

Crea:

- /Users/Shared/dcmtk/wlmscpfs/[org]  y contenido
- /Library/LaunchDaemons/wlmscpfs.[org].[aet].[puerto].plist
- /Users/pcs2/Documents/dcmtk/wlmscpfs.[org].[aet].[puerto].log
- /Users/pcs2/Documents/dcmtk/wlmscpfs.[org].[aet].[puerto].error.log