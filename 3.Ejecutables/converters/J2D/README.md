# J2D

 Serialization of DCKV JSON to DICOM binary (one dataset only)

In DCKV JSON, large binary objects of the dataset are represented inn one of the following ways :
1)  base64 inline
2)  absolute URL referencinng the DICOM original
3)  relative URL referencing bulkdata files or aliases of them gathered in a DCKV.bulkdata directory next to the DCKV.json file

## stdin
DCKV JSON (when no file is passed as argument)
Accepts :
- JSON contents (eventual relative url bulkdata files are looked for in DCKV.bulkdata of the current directory)
- MIME dicom zip retrieve format ( the zip shall contain the eventual relative url bulkdata files)

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
