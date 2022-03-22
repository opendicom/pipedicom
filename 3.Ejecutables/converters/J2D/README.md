# J2D

EDCKV JSON to DICOM binary
Relative references are applied from current directory 

In EDCKV JSON, large binary objects are represented as :
1)  base64 inline
2)  absolute or relative URL referencing a portion of the original DICOM binary from which they were derived
3)  relative URL referencing bulkdata files or aliases of them gathered in a DCKV.bulkdata directory next to the DCKV.json file

Relative references are applied from the current directory 

## env
J2DLogLevel : [ DEBUG | VERBOSE | INFO | WARNING | ERROR | EXCEPTION ]
default : ERROR

## args
J2D [ undf | natv | j2kb | j2kf | j2kh | j2ki | j2kr | j2k ] [ path ]

no args : default undf for arg1
two args: the second one is a path which replaces stdin

arg1 may imply conversions.

- (undf) undefined: defaults to j2k, or native or what is into dataset in this order depending of the existence of the sets.
- (natv) native: explicit little endian without compression
- (j2kb) j2kBase: the quality of a miniature.
- (j2kf) j2kFast: compressión con pérdida, pero muy rápido, compuesta de 2 capas
- (j2kh) j2kHres: compressión con pérdida invisible, compuesta de 3 capas
- (j2ki) j2kIdem: compresión sin perdida, compuesta de 4 capas
- (j2kr) j2kr: compresión sin perdida, compuesta de una capa
- (j2k) j2k: j2kIdem o j2kr


## stdin
DCKV file Path

## stderr
errors
"2>" redirect to file

## stdout
dicom binary
">" redirect to file
