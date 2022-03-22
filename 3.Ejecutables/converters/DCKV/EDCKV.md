#EDCKV

Es un formato de "entry" para la comunicación de uno o más datasets DCKV y metadata útil para administración y/o transformación de instancias dicom.

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
| string2 | [0..n]   | <string @key> | children object id                                  |
+---------+----------+---------------+-----------------------------------------------------+
| map3    | [0..n]   | <map>         | named list of url references                        |
| string3 | [0..n]   | <string>      | string and base 64 encoded binary attributes values |
| number3 | [0..n]   | <number>      | numeric attributes values                           |
+---------+----------+---------------+-----------------------------------------------------+
| array4  | [0..n]   | <array @key>  | alternative urls to resources                       |
+---------+----------+--------+------+-----------------------------------------------------+
| string5 | [0..n]   | <string>      | url(s) to fragments or to one resource              |
+---------+----------+--------+------+-----------------------------------------------------+

```

# EDCKV's maps

"map1" in EDCKV is also called "set". Sets are named. Some are of reserved use.

- "dataset" is the base one. It can contain everything.

- "filemetainfo" may also exist and contain group2 attributes, in which it replaces any group2 attributes which may be found in "dataset". The attribute 00000001_00020010-UI (transfert syntax) shall be communicated in "filemetainfo" when EDCKV is serialized.

- "native" and/or "j2kr"/"bfhi" are DCKV reserved names and contain non group 2 attributes corresponding to explicit little endian and j2k transfer representations respectively. When "native" and/or "j2kr"/"bfhi" are present in EDCKV, dataset does not contain any of the same attributes as in "native" or "j2kr"/"bfhi". When both "native" and "j2k" are present, only one is used for serializing, depending on the directive pixelMode.

- Other dictionaries found override "dataset" (in any order).

- If a dictionary is called "remove", this is the last to be processed and its effect is to remove the corresponding attributes from "dataset".

