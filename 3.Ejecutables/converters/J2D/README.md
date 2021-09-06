# J2D

DCKV JSON to DICOM binary
Relative references are applied from current directory 

In DCKV JSON, large binary objects are represented as :
1)  base64 inline
2)  absolute or relative URL referencing the original DICOM binary from which they were derived
3)  relative URL referencing bulkdata files or aliases of them gathered in a DCKV.bulkdata directory next to the DCKV.json file

Relative references are applied from current directory 

## env
J2DLogLevel : [ DEBUG | VERBOSE | INFO | WARNING | ERROR | EXCEPTION ]
default : ERROR

## args
J2D [ native | j2kbase | j2kfast | j2khres | idem ]

native: if j2k compressed, decompress it, else idem
j2base: if j2k compressed, with base layer only, else idem
j2fast: if j2k compressed, with base and fast layers only, else  idem
j2hres: if j2k compressed, with base,fast and hres layers only, else idem
idem: as in json with full information

no arg : default idem

## stdin
DCKV file Path

## stderr
errors
"2>" redirect to file

## stdout
dicom binary
">" redirect to file
