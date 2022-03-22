# D2J

DICOM binary to DCKV JSON blobModeResources

## args
Space separated list of paths to files or folders containing  DICOM binary dataset or part10 file in stdin.

## Environment
- "D2JlogLevel" (authorized values: "DEBUG","VERBOSE","INFO","WARNING","ERROR","EXCEPTION"). If the variable is not set, the default log level is "ERROR"
- "D2Joutput" path where to write the output. Defaults to current folder
- "D2JrelativePathComponents" number of components starting at path name, backwards which are repeated in the output file path
- "D2JblobMinSize", minimal size which triggers output reference instead of inlined representation of binary contents.
- "D2JblobRefPrefix"
- "D2JblobRefSuffix"
- "D2Jpixel" [ natv | j2kr | j2ki ]



## stderr
errors
"2>" redirect to file

## stdout
err number
">" redirect to file

