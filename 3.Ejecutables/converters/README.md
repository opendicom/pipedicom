# Converters

DCKV (Dicom Contextualized-Key Values) may be used  for parsing. The result is a map of keyed arrays in memory. The  map corresponds to the dataset. Each key is a concatenation of the tag of the attribute and the tags of its context sequences. Each array contains zero or more values for the attribute.

This fairly simple construct in memory may be fastly serialized into JSON  where map and array are the two structuring artifacts. It allows granular access to any of the bits of information as XPath do for the XML based representation. 

Moreover, from JSON map of array, there exists a standard translation into a corresponding construct in XML thanks to the XPath3.1 json2xml() function.


## Converters stack

xml -> xslt -> xml
      \             /
          json
             |
        dicom


## dicom -> json converter blob modes

Three alternative blob modes are implemented in the converter dicom -> json:
- source: json attributes contain an url pointing at a subarray of bytes within the original dicom file
- inline: the attributes contain the blob coded base64 within a string
- resources: json attributes contain an url pointing to a distinct external file for each of the blobs

inline is always used for blobs smaller than a minimal size.


## optional conversion native explicit little endian to j2k enclosed

When json converter blob mode is inline or resources, that is when the product does not refer to the original, we added an option to convert on the flight native explicit little endian to j2k enclosed.


## JSON representation of blobs




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
