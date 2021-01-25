# M2

mapxmldicom object Tranformer.


## options
Path(s) to xslt to be applied succesively.
The xslt file name may be echoed with the name of a environment variable wich contains parameters in the form of a single level json object listing key-value params  

## Environment
Apart from eventual parameters for the application of xslt transformations, the executable also looks for:
- "M2logLevel" (authorized values: "DEBUG","VERBOSE","INFO","WARNING","ERROR","EXCEPTION"). If the variable is not set, the default log level is "ERROR"
- "M2logPath" (should point to a path within "/Users/Shared" or "/Volumes/LOG"). Otherwise, the default log path is "/Users/Shared/D2M.log".
- "M2testPath" (path to a binary dicom file part 10 or dataset). If set, this file is used instead of the stdin.

## stdin
M2 dataset or dicom part 10 file

## stderr
Logging

## stdout
The result of the application of one or more xslt on mapxmldicom. 

If the last xslt1 tranformer is "D.xsl", the programs serializes the result in either:
- a dataset (in case the M does not contain group 2 attributes).
- a dicom part 10 file (when M contains group 2 attributes).
