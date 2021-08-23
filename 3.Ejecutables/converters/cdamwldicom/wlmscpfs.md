# wlmscpfs

__[documentación](https://support.dcmtk.org/docs/wlmscpfs.html)__

__[FAQ](https://forum.dcmtk.org/viewtopic.php?t=84)__

```
Note: The wlmscpfs tool expects a data directory (identified with the -dfp option) that has one or more Subdirectories matching the AE titles to which the tool is expected to respond.
```

Invocación básica del ejecutable:
```
wlmscpfs -dfp /Users/Shared/wlmscpfs/aet 2575
```

En /Users/Shared/wlmscpfs/aet están carpetas para cada aet que pueda ser invocada.En nuestro caso creamos una subcarpeta "DCM4CHE" para no tener que cambiar la configuración de los equipos imagenológicos.

Dentro de esta carpeta se agregan archivos con extensión .wl que contienen los items de la worklist.


Opciones de wlmscpfs permiten analizar los requests que provienen de las modalidades y mejorar el contenido de los archivos .wl para satisfacer los pedidos.


