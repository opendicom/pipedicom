# pipedicom
shell scripts for pacs connectivity streaming pipelines

## Objetivo

Dentro de una red DICOM y cada vez más entre redes DICOM contectadas por VPN, nos piden instalar flujos de datos que van de un PACS a otro u a aplicación de historia clínica.

En lugar de repetir una y otra vez la creación de scripts largos para cumplir con la tarea, creemos posible crear pequeñas unidades funcionales que llamamos "eslabones" y alinearlos dentro de pipelines gracias a toda la tecnología correspondiente presente en los los lenguajes de comando (que llamaremos genericamente "sh" en todo este proyecto e incluyen sh, bash, zsh, etc). En particular nos referimos por ejemplo al pipe "|" que redirecciona los datos que salen de un modulo a la entrada de otro.

Dentro de los objetivos de este proyecto, agregamos un esfuerzo repetido una y otra vez para lograr módulos cada vez más compactos y genericos y en contra parte pipelines con cada vez más eslabones. A largo plazo podría ser la base para la formalización de un lenguaje composicional para objetos DICOM. La ruta hasta allí es muy larga pero el sol brilla al horizonte.

## Recursos

Intentamos limitar las dependencias externas. Con la excepción de la dependencia a proyectos de código libre infinitamente populares y admirables por su excelente traducción en código ejecutable a los estándares más universales DICOM y de communicación:

- curl para comunicación http
- librarías dicom sh
   - dcmtk
   - dcm4che
   - saxon
   - etc
   
## Limitationes

Nos limitamos a la plataforma linux. Inicialmente Centos.


## Capitulos del proyecto

1. Conceptos
2. Triggers
3. Ejecutables
4. Eslabones
5. Cadenas
