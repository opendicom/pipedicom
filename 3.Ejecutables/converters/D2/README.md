# D2J

DICOM binary to DCKV JSON

## stdin
DICOM binary dataset or part10 file

## args
When args are used, stdin is not. args is made of a space separated list of paths to files or folders containing  DICOM binary dataset or part10 file in stdin.

## Environment
Apart from eventual parameters for the application of xslt transformations, the executable also looks for:
- "D2JlogLevel" (authorized values: "DEBUG","VERBOSE","INFO","WARNING","ERROR","EXCEPTION"). If the variable is not set, the default log level is "ERROR"
- "D2JlogPath" (should point to a path within "/Users/Shared" or "/Volumes/LOG"). Otherwise, the default log path is "/Users/Shared/D2M.log".
- "D2Joutput" path where to write the output. If set, it replaces the stdout (/dev/stdout)
- "D2JrelativePathComponents" number of components starting at path name, backwards which are repeated in the output file path
- "D2JblobMinSize", minimal size which triggers output reference instead of inlined representation of binary contents.
- "D2JblobMode" : [ blobModeSource | blobModeResources | blobModeInline ]. Default: blobModeInline. 
- "D2JblobRefPrefix"
- "D2JblobRefSuffix"
- "D2JcompressJ2K" convierte explicit little endian a jpeg 2000 lossless
- "D2JforceZip". When the result is made of one object only, D2M returns the object as is, unless D2JforceZip is true. By default, when D2M returns various objects to stdout, it already creates a zipped stream. But when D2M returns various objects to the outputDir, it does so by default as a structured filesystem. When D2MforceZip is true, it writes a unique zip written in the outputDir named with a new UUID string name and returns the UUID in the stdout



## stderr
logging

## stdout
D2JforceZip | D2JoutputDir | args   | stdout   | stdout error
------------|--------------|--------|----------|---------------
false       | true         |        | 0        | err number > 0
false       | false        | 0-1    | json     | err number > 0
true        | false        |        | zipped   | err number > 0
false       | false        | >1     | zipped   | err number > 0
true        | true         |        | zip name | err number > 0
