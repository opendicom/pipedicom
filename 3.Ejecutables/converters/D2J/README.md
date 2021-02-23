# D2J

Dicom binary to JSON mapxmldicom


## Environment
Apart from eventual parameters for the application of xslt transformations, the executable also looks for:
- "D2MlogLevel" (authorized values: "DEBUG","VERBOSE","INFO","WARNING","ERROR","EXCEPTION"). If the variable is not set, the default log level is "ERROR"
- "D2MlogPath" (should point to a path within "/Users/Shared" or "/Volumes/LOG"). Otherwise, the default log path is "/Users/Shared/D2M.log".
- "D2MtestPath" (path to a binary dicom file part 10 or dataset). If set, this file is used instead of the stdin.
- "D2Moutput" path where to write the output. If set, it replaces the stdout (/dev/stdout)

## stdin
DICOM binary dataset or part10 file

## stderr
logging

## stdout
JSON mapxmldicom
