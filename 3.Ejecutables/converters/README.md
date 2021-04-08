# Converters

DCKV (Dicom Contextualized-Key Values) may be used  for parsing. This results to a map of keyed arrays in memory. The  map corresponds to the dataset. On the one hand, each key is a concatenation of the tag of the attribute and the tags of its context sequences. On the other hand, each array contains zero or more values for the attribute.

This fairly simple construct in memory may be fastly serialized into JSON file where map and array are the two structuring artefacts. JSON - and BSON, similar but better for binary contents - are our preferred file formats for DICOM.

From JSON map of array, there exists a standard translation into a corresponding construct in XML thanks to the XPath3.1 json2xml() function.

## "D2dict": parsing from DICOM to map of array
The function "D2dict" is found in the framework DCKV. It can be used by other programs by linking to the framework.

### "D2J": serializing into JSON of the parsing
"D2J" is a terminal utility using the framework DCKV to convert a dataset from the DICOM binary into the JSON representations. "D2J" supports DICOM input streaming and JSON output streaming.

## "dict2D": serializing from map of array to DICOM
The function "dict2D" is found in the framework DCKV. It can be used by other programs by linking to the framework.

### "J2D": serializing from JSON to DICOM
"J2D" is a terminal utility using the framework DCKV to convert a  dataset from the JSON into the DICOM binary representations. "J2D" supports JSON input streaming and DICOM output streaming.

## Round trip
Applying succesively "D2J" and "J2D", we obtain a round trip which is equivalent to identity.

The same round trip can be performed with the tools dcm2json and json2dcm of the dcm4che toolkit. 

Both our and dcm4chee toolkits offer the option of pointing to binary data by uri  (in replacement of the inefficiant inline base64 data). We use this option on both sides for a fair comparison of the performance of dataset processing.

```
export start=$(gdate +%s.%N); \
dcm2json dataset.dcm | json2dcm -j - -o dcm4che_dataset.dcm; \
export stop=$(gdate +%s.%N); \
echo "$stop - $start" | bc

->   .425010000

export start=$(gdate +%s.%N); \
D2J dataset.dcm | J2D > DCKV_dataset.dcm; \
export stop=$(gdate +%s.%N); \
echo "$stop - $start" | bc

->   .041595000
```
The test shows that our toolkit for the round trip is near ten times faster.
