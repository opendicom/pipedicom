# Eslabones de una cadena



Para recuperar la linea de información del stdin, el script del comando necesita implementar la estructura siguiente:

```
#!/bin/sh

while read line; do

echo "${line}"

done 

exit 0
```

la variable ${line} recibe stdin. `echo` crea una linea en stdout. este script ejemplo mínimo (totalmente inútil) funcionaría como proxy sin ninguna modificación del stream.

Colocar algo útil entre do y done en base a los argumentos del comando y de ${line} como linea de stdin. Se crea el stdout mediante uno o más comandos `echo`.




