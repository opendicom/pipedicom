# opendicom/cdamwldicom/install.sh

cdamwldicom consulta el pacs central para recibir las citas que corresponden a la organización local. Las transforma en items de modality worklist para wlmcspfs

Para instalarlo, ejecutar opendicom/cdamwldicom/install.sh con sudo y parametros:

- admin
- org
- branch
- qido for branch OT

Ejemplo:

```sh
/Users/Shared/opendicom/cdamwldicom/install.sh pcs2 asseSAINTBOIS DCM4CHEE "https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE/instances?Modality=OT&amp;00080080=asseSAINTBOIS&amp;SeriesDescription=solicitud&amp;NumberOfStudyRelatedInstances=1&amp;StudyDate="
```

Crea:

- /Users/Shared/opendicom/cdamwldicom/[branch]  y contenido
- /Users/pcs2/Library/Launchagents/cdamwldicom.[branch].[org].plist
- /Users/pcs2/Documents/opendicom/cdamwldicom.[branch].[org].log
- /Users/pcs2/Documents/opendicom/cdamwldicom.[branch].[org].error.log