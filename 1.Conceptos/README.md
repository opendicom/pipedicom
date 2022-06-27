# 1. Conceptos

sh permite ejecutar comandos y visualizar el resultado de la ejecución dentro de una ventana de tipo terminal textual dónde se agregan nuevas lineas de texto al pie de las existentes a medida que se ingresan comandos y generan resultados.

A esta ventana corresponde un entorno de ejecución con sus variables propias que persisten más alla de cada comando hasta que se cierre la ventana. En todo tiempo se puede listar las variables de entorno con el comando "printenv".

Es posible abrir varias ventanas a la vez y trabajar en cada una de ellas en paralelo. Además se puede usar archivos como si fuesen ventanas. Por ejemplo una ventana puede escribir a archivo y otra leer desde el mismo archivo.

## Comando

Un comando tiene un nombre.

Está ejecutado si se escribe dentro de una ventana y luego se finaliza la linea con un return. 

También se ejecuta si está incluido en un listado de lineas de comandos (un script) que fue ejecutado como si fuese un comando simple, mediante el nombre del script.

Cada comando, y cada script igual, tiene una interfaz de entrada (stdin) y dos interfaces de salidas (stdout y stderr)

## Interfaces

La entrada es 



