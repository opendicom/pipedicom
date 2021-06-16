# D2J

DICOM binary to DCKV JSON blobModeResources

## stdin
DICOM binary dataset or part10 file

## args
Space separated list of paths to files or folders containing  DICOM binary dataset or part10 file in stdin.

## Environment
- "D2JlogLevel" (authorized values: "DEBUG","VERBOSE","INFO","WARNING","ERROR","EXCEPTION"). If the variable is not set, the default log level is "ERROR"
- "D2JlogPath" (should point to a path within "/Users/Shared" or "/Volumes/LOG"). Otherwise, the default log path is "/Users/Shared/D2M.log".
- "D2Joutput" path where to write the output. Defaults to current folder
- "D2JrelativePathComponents" number of components starting at path name, backwards which are repeated in the output file path
- "D2JblobMinSize", minimal size which triggers output reference instead of inlined representation of binary contents.
- "D2JblobRefPrefix"
- "D2JblobRefSuffix"
- "D2JcompressJ2K" convierte explicit little endian a jpeg 2000 lossless with quality layers separated into tile-parts



## stderr
logging

## stdout
err number
