#  DCKV

DCKV es un formato de dataset parte del formato EDCKV (Entry Dicom Contextualized Key-Values)

##EDCKV
```
<map0>
  |
  +-----------+-----------+-----------+-----------+-----------+
  |           |           |           |           |           |
<map1>     <string1>    <true1>    <false1>    <number1>   <array1>
  |                                                           |
  +-----------+                                               |
  |           |                                               |
<array2>   <null2>                                         <string2>
  |
  +-----------+----------+
  |           |          |  
<map3>    <string3>   <number3>
  |
  |
  |
<array4>
  |
  |
  |
<string5>



+=========+==========+===============+=====================================================+
| level   | how many | object        | description                                         |
+=========+==========+===============+=====================================================+
| map0    | 1        | <map>         | root                                                |
+----------+---------+---------------+-----------------------------------------------------+
| map1    | [0..n]   | <map @key>    | dataset(s)                                          |
| string1 | [0..n]   | <string @key> | object id                                           |
| true1   | [0..1]   | <true @key>   | IOCM keep                                           |
| false1  | [0..1]   | <false @key>  | IOCM obfuscate                                      |
| number1 | [0..n]   | <map @key>    | number of descendant sop instances                  |
| array1  | [0..n]   | <array @key>  | list of children ids (e.j series of a study module) |
+---------+----------+---------------+-----------------------------------------------------+
| array2  | |0..n]   | <array @key>  | attributes                                          |
| null2   | |0..n]   | <null @key>   | end SQ, start and end ite                           |
| string2 | [0..n]   | <string @key> | children id                                         |
+---------+----------+---------------+-----------------------------------------------------+
| map3    | [0..n]   | <map>         | named list of url references                                  |
| string3 | [0..n]   | <string>      | string and base 64 encoded binary attributes values |
| number3 | [0..n]   | <number>      | numeric attributes values                           |
+---------+----------+---------------+-----------------------------------------------------+
| array4  | [0..n]   | <array @key>  | alternative urls to resources              |
+---------+----------+--------+------+-----------------------------------------------------+
| string5 | [0..n]   | <string>      | url(s) to fragments or to one resource              |
+---------+----------+--------+------+-----------------------------------------------------+

```

Nota: when map1 is named "remove", elimina los atributos de mismo key del dataset al cual se agrega el dataset "remove".

##DCKV
```
<map1>
  |
  +-----------+
  |           |
<array2>   <null2>
  |
  +-----------+----------+
  |           |          |  
<map3>    <string3>   <number3>
  |
  |
  |
<array4>
  |
  |
  |
<string5>



+=========+==========+===============+=====================================================+
| level   | how many | object        | description                                         |
+=========+==========+===============+=====================================================+
| map1    | 1        | <map @key>    | dataset(s)                                          |
+---------+----------+---------------+-----------------------------------------------------+
| array2  | |0..n]   | <array @key>  | attributes                                          |
| null2   | |0..n]   | <null @key>   | end SQ, start and end item                           |
| string2 | [0..n]   | <string @key> | children id                                         |
+---------+----------+---------------+-----------------------------------------------------+
| map3    | [0..n]   | <map>         | named list of url references                        |
| string3 | [0..n]   | <string>      | string and base 64 encoded binary attributes values |
| number3 | [0..n]   | <number>      | numeric attributes values                           |
+---------+----------+---------------+-----------------------------------------------------+
| array4  | [0..n]   | <array @key>  | alternative urls to resources              |
+---------+----------+--------+------+-----------------------------------------------------+
| string5 | [0..n]   | <string>      | url(s) to fragments or to one resource              |
+---------+----------+--------+------+-----------------------------------------------------+

```

map3 has one of the following keys:
- Native
- Fragment#00000001 (fragment number - there may be many fragments in a frame, applies to source blob mode only)
- Frame#00000001 (frame number applies to any mode)
- FrameBFHI#00000001 (frame number applies to any mode. Refers to a j2k 4 quality levels)
- pdf (kind of encapsulated document)
- xml (kind of encapsulated document - DICOM call it encapsulated CDA)
- stl (kind of encapsulated document)
- obj (kind of encapsulated document)
- mtl (kind of encapsulated document)

