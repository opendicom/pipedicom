# B2M

Bson to mapxmldicom

## options
Path(s) to xslt to be applied succesively.
The xslt file name may be echoed with the name of a environment variable wich contains parameters in the form of a single level json object listing key-value params  

## Environment
Apart from eventual parameters for the application of xslt transformations, the executable also looks for:
- "B2MlogLevel" (authorized values: "DEBUG","VERBOSE","INFO","WARNING","ERROR","EXCEPTION"). If the variable is not set, the default log level is "ERROR"
- "B2MlogPath" (should point to a path within "/Users/Shared" or "/Volumes/LOG"). Otherwise, the default log path is "/Users/Shared/D2M.log".
- "B2MtestPath" (path to a binary dicom file part 10 or dataset). If set, this file is used instead of the stdin.
- "B2Moutput" path where to write the output. If set, it replaces the stdout (/dev/stdout)

## stdin
bson binary file of either a dataset or a dicom part 10 file (if group 2 is present)

## stderr
logging

## stdout
mapxmldicom, or the result of the application of one or more xslt on mapxmldicom
