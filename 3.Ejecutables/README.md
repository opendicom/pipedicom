# 3.Ejecutables

Cada ejecutable cumple una acción entre input y output.

## Usan los terminales de la siguiente forma:

- stdin lee el input stream
- stdout escribe el output stream
- el nombre del ejecutable se usa para llamarlo
- cada ejecutable puede definir sus propios parametros obligatorios o opcionales que se escriben a continuación del nombre del ejecutable
- Variables de entorno XlogLevel, XlogPath y XtestPath prefijadas con el nombre del ejecutable X Facilitan la auditoria y el debugging de los ejecutables

## Nombre de los ejecutables
El nombre de los ejecutables empieza con dos mayusculas. La primera indica el tipo de input y la segunda el tipo de output

Lista de los tipos de input y output:
