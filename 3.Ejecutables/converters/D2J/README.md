# D2J

DICOM binary to DCKV JSON

## stdin
DICOM binary dataset or part10 file

## args
When args are used, stdin is not. args is made of a space separated list of paths to files or folders containing  DICOM binary dataset or part10 file in stdin.

If args starts with the word test, the following args are name of testfiles available within the framework

## Environment
Apart from eventual parameters for the application of xslt transformations, the executable also looks for:
- "D2MlogLevel" (authorized values: "DEBUG","VERBOSE","INFO","WARNING","ERROR","EXCEPTION"). If the variable is not set, the default log level is "ERROR"
- "D2MlogPath" (should point to a path within "/Users/Shared" or "/Volumes/LOG"). Otherwise, the default log path is "/Users/Shared/D2M.log".
- "D2Moutput" path where to write the output. If set, it replaces the stdout (/dev/stdout)
- "D2MrelativePathComponents" number of components starting at path name, backwards which are repeated in the output file path
- "D2MbyRefToOriginalMinSize", minimal size which triggers output reference instead of inlined representation of binary contents.
- "D2MforceZip". When the result is made of one object only, D2M returns the object as is, unless D2MforceZip is true. By default, when D2M returns various objects to stdout, it already creates a zipped stream. But when D2M returns various objects to the outputDir, it does so by default as a structured filesystem. When D2MforceZip is true, it writes a unique zip written in the outputDir named with a new UUID string name and returns the UUID in the stdout


## stderr
logging

## stdout
D2JforceZip | D2JoutputDir | args | stdout
---|---|---|---
true|true| |zip written in outputDir and UUID name string of the zip in output
false|true| |int 0=OK, else any err number
true|false| |zipped
false|false|0-1|xml or result of xslt1 transformation(s)
false|false|test + 1| xml or result of xslt1 transformation(s)
false|false|>1| zipped
