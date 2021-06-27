# J2D

DCKV JSON to DICOM binary
Relative references are applied from current directory 

In DCKV JSON, large binary objects are represented as :
1)  base64 inline
2)  absolute or relative URL referencing the original DICOM binary from which they were derived
3)  relative URL referencing bulkdata files or aliases of them gathered in a DCKV.bulkdata directory next to the DCKV.json file

Relative references are applied from current directory 

## args
(default: dcmj2kidem)
[ dcmnative | dcmj2kbase | dcmj2kfast | dcmj2khres | dcmj2kidem ]  

## stdin
DICOM filePath

## stderr
errors

## stdout
dicom binary
