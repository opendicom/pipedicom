# D2

DICOM binary to DCKV JSON blobModeResources

## args
Space separated list of paths to files or folders containing  DICOM binary dataset or part10 file in stdin.

## Environment
- "D2logLevel" (authorized values: "DEBUG","VERBOSE","INFO","WARNING","ERROR","EXCEPTION"). If the variable is not set, the default log level is "ERROR"
- "D2logPath" (should point to a path within "/Users/Shared" or "/Volumes/LOG"). Otherwise, the default log path is "/Users/Shared/D2M.log".
- "D2output" path where to write the output. Defaults to current folder
- "D2relativePathComponents" number of components starting at path name, backwards which are repeated in the output file path
- "D2blobMinSize", minimal size which triggers output reference instead of inlined representation of binary contents.
- "D2blobRefPrefix"
- "D2blobRefSuffix"
- "D2compressJ2K" convierte explicit little endian a jpeg 2000 lossless with quality layers separated into tile-parts



## stderr
logging

## stdout
err number
