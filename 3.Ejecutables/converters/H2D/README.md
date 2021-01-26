# H2D

hexa (H) is a codification of binary DICOM available in dcm_attrs blobs of dcm4chee mysql databases.

It is very inefficient but remains complete in a string type answer to a command line query to mysql. In Mysql 5.6, we experienced problems with the alternative base64 codification. This is the reason why we use hexa.

This executable is normally piped to D2M

## options
none

## Environment
Apart from eventual parameters for the application of xslt transformations, the executable also looks for:
- "H2DlogLevel" (authorized values: "DEBUG","VERBOSE","INFO","WARNING","ERROR","EXCEPTION"). If the variable is not set, the default log level is "ERROR"
- "H2DlogPath" (should point to a path within "/Users/Shared" or "/Volumes/LOG"). Otherwise, the default log path is "/Users/Shared/D2M.log".
- "H2DtestPath" (path to a binary dicom file part 10 or dataset). If set, this file is used instead of the stdin.
- "H2Doutput" path where to write the output. If set, it replaces the stdout (/dev/stdout)

## stdin
dataset codified in hexa

## stderr
Logging

## stdout
dataset in binary dicom 
