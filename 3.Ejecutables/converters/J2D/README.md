# J2D

DCKV JSON to DICOM binary
Relative references are applied from current directory 

In DCKV JSON, large binary objects are represented as :
1)  base64 inline
2)  absolute URL referencing the original DICOM binary from which they were derived
3)  relative URL referencing bulkdata files or aliases of them gathered in a DCKV.bulkdata directory next to the DCKV.json file

## stdin
DCKV JSON (when no file is passed as argument)
Accepts :
- JSON contents (eventual relative url bulkdata files are looked for in DCKV.bulkdata of the current directory)

## args
syntax 1: inputURL
syntax 2: test filename (found in DCKV framework)

## Environment
- "J2DlogLevel" (authorized values: "DEBUG","VERBOSE","INFO","WARNING","ERROR","EXCEPTION"). If the variable is not set, the default log level is "ERROR"
- "J2DlogPath" (should point to a path within "/Users/Shared" or "/Volumes/LOG"). Otherwise, the default log path is "/Users/Shared/D2M.log".


## stderr
logging

## stdout
dicom file
