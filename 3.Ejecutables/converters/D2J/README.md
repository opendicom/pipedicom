# D2J

Dicom binary to JSON mapxmldicom

export start=$(gdate +%s.%N);./D2J /Volumes/GITHUB/pipedicom/3.Ejecutables/converters/Formats/D/FluroWithDisplayShutter.dcm | ./J2D > /Users/Shared/a.dcm; export stop=$(gdate +%s.%N); echo "$stop - $start" | bc

.041595000


export start=$(gdate +%s.%N);./dcm2json /Volumes/GITHUB/pipedicom/3.Ejecutables/converters/Formats/D/FluroWithDisplayShutter.dcm | ./json2dcm -j - -o /Users/Shared/dcm4che.dcm; export stop=$(gdate +%s.%N); echo "$stop - $start" | bc

.286682000

## Environment
Apart from eventual parameters for the application of xslt transformations, the executable also looks for:
- "D2MlogLevel" (authorized values: "DEBUG","VERBOSE","INFO","WARNING","ERROR","EXCEPTION"). If the variable is not set, the default log level is "ERROR"
- "D2MlogPath" (should point to a path within "/Users/Shared" or "/Volumes/LOG"). Otherwise, the default log path is "/Users/Shared/D2M.log".
- "D2Moutput" path where to write the output. If set, it replaces the stdout (/dev/stdout)

## stdin
DICOM binary dataset or part10 file

## stderr
logging

## stdout
JSON mapxmldicom
