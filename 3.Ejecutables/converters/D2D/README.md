# D2D

DICOM binary to DICOM binary with compresión and coerción inbetween

## args

receiverDirPath. Spool directory which contains: 
- RECEIVED, 
- ORIGINALS, 
- DISCARDED, 
- COERCED(alternative)

coercedDirPath (normal dest directory for coerced files)


## Environment
- "D2DlogLevel" (authorized values: "DEBUG","VERBOSE","INFO","WARNING","ERROR","EXCEPTION"). If the variable is not set, the default log level is "ERROR"
- "D2DlogPath" (should point to a path within "/Users/Shared" or "/Volumes/LOG"). Otherwise, the default log path is "/Users/Shared/D2M.log".
- "D2DcompressJ2K" convierte explicit little endian a jpeg 2000 lossless with quality layers separated into tile-parts.
- "D2DjsonDataset" attributes overriding the originals

## stderr
logging

## stdout
0=success
