# Instalación PCS2

Se dedican puertos distintos para distintos branchs, empezando en 4096 para el servicio storescp y en 11112 para el servicio findscp:

Dos opciones:

## Opción rápida

```
sudo /Users/Shared/install/install1.sh asseSAINTBOIS
sudo /Users/Shared/install/install2.sh asseHOSPOJOS
```

install1 reserva los puertos 4096 y 11112 e instala tambien storedicom

install2 reserva los puertos 4097 y 11113

Es sencillo duplicar install2 como install[n] y cambiar los puertos dentro de los duplicados, para realizar instalaciones de más de dos organizaciones dentro del mismo pcs2.

# Verificación de la instalación

# Iniciar todos los servicios

```
/Users/Shared/start_all.sh 
```

```
-	0	cdamwldicom.asseHOSPOJOS.DCM4CHEE.plist
-	0	cdamwldicom.asseHOSPOJOS.DCM4CHEE
-	0	olditems.asseHOSPOJOS.DCM4CHEE.plist
-	0	cdamwldicom.asseSAINTBOIS.DCM4CHEE.plist
-	0	olditems.asseSAINTBOIS.DCM4CHEE.plist
-	0	storedicom.DCM4CHEE.plist
-	0	coercedicom.asseHOSPOJOS.plist
-	0	coercedicom.asseSAINTBOIS.plist
-	0	coercedicom.asseHOSPOJOS.plist
7448	0	storescp.asseHOSPOJOS.4097.plist
7455	0	storescp.asseSAINTBOIS.4096.plist
7462	0	wlmscpfs.asseHOSPOJOS.DCM4CHEE.11113.plist
7469	0	wlmscpfs.asseSAINTBOIS.DCM4CHEE.11112.plist
```

Storescp y wlmscpfs tienen un nro de proceso porque están abiertos en forma permanente para escuchar sus puertos respectivos.

Se puede comprobar la apertura de los puertos usando el programa "utilidad de red"

![UtilidadDeRed](UtilidadDeRed.png)



# Terminar todos los servicios

```
/Users/Shared/stop_all.sh 
```

```
-	0	cdamwldicom.asseHOSPOJOS.DCM4CHEE.plist
-	0	cdamwldicom.asseHOSPOJOS.DCM4CHEE
-	0	olditems.asseHOSPOJOS.DCM4CHEE.plist
-	0	cdamwldicom.asseSAINTBOIS.DCM4CHEE.plist
-	0	olditems.asseSAINTBOIS.DCM4CHEE.plist
-	0	storedicom.DCM4CHEE.plist
-	0	coercedicom.asseHOSPOJOS.plist
-	0	coercedicom.asseSAINTBOIS.plist
-	0	coercedicom.asseHOSPOJOS.plist
7448	0	storescp.asseHOSPOJOS.4097.plist
7455	0	storescp.asseSAINTBOIS.4096.plist
7462	0	wlmscpfs.asseHOSPOJOS.DCM4CHEE.11113.plist
7469	0	wlmscpfs.asseSAINTBOIS.DCM4CHEE.11112.plist
```



# Uninstall all

¡Atención! Borra TODAS las organizaciones instaladas y TODOS los objetos dicom tratados.

Es irreversible.

Se puede usar para reciclar un pcs2 para una otra organización

```
sudo /Users/Shared/install/uninstall_all.sh
```

