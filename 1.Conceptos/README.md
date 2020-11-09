# 1. Conceptos

sh permite ejecutar comandos y visualizar su ejecución dentro de una ventana de tipo terminal textual adónde se agregan nuevas lineas de texto al pie de las lineas ya existentes a medida que se ingresa o se genera automaticamente resultados de los comandos ejecutados.

La ventana corresponde a un entorno de trabajo con sus variables propias que persisten más alla de cada comando hasta que se cierre la ventana. En todo tiempo se pueden listar con el comando "printenv".

Es posible abrir varias ventanas a la vez e interactuar con cada una de ellas en paralelo. Por ejemplo una se usa para ingresar información y otra muestra resultados. Además se puede usar archivos como si fuesen ventanas. Por ejemplo una ventana puede escribir a archivo y otra leer desde el mismo archivo.

## Comando

Un comando tiene un nombre.

Está ejecutado si se escribe dentro de una ventana y luego se cierra la linea con un return. 

También se ejecuta si está incluido en un listado de lineas de comandos (un script) que fue ejecutado como si fuese un comando simple, mediante el nombre del script.

Cada comando, y cada script igual, tiene una interfaz de entrada (stdin) y dos interfaces de salidas (stdout y stderr)

## Interfaces

La entrada es 



