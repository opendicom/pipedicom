# Converters

Using DCKV (Dicom Contextualized-Key Values) , each parsing results in a map of keyed arrays in memory. The  map corresponds to the dataset. Each key is made of the tags of the attribute and its context. Each array correponding to a key contains zero or more values of the attribute.

This simple object is fastly serialized into JSON files where map and array are the two structuring artefacts. JSON (and better for binary contents BSON) are our preferred file formats for DICOM.

From JSON map of array, there is a standard translation to a corresponding construct in XML thanks to the XPath3.1 json2xml() function.

## Parsing from DICOM to map of array
The corresponding function "D2dict" is found in the framework DCKV. Can be used by other programs by linking to the framework.

### Serializing into JSON of the parsing
"D2J" is a terminal utility using the framework DCKV. D2J supports input streaming of DICOM and output streaming of JSON.

## Serializing from map of array to DICOM
"dict2D" is found in the framework DCKV. Can be used by other programs by linking to the framework.

### Serializing from JSON to DICOM
When the serialization starts with a JSON file or stream, J2D is the terminal utility using the framework DCKV and doing this job.

## Round trip
Applying succesively D2J and J2D, we obtain a round trip which is equivalent to identity.

The same round trip can be performed with the tools dcm2json and json2dcm of dcm4che toolkit. 

Both our and dcm4chee toolkits offer the pointers to binary data by uri alternative (in replacement of the inefficiant inline base64 data). This means a fair comparison of the performance is posible.

```
jf-6:bin jacquesfauquex$ export start=$(gdate +%s.%N);./dcm2json /Volumes/GITHUB/pipedicom/3.Ejecutables/converters/Formats/D/FluroWithDisplayShutter.dcm | ./json2dcm -j - -o /Users/Shared/dcm4che.dcm; export stop=$(gdate +%s.%N); echo "$stop - $start" | bc
.425010000

jf-6:Debug jacquesfauquex$ export start=$(gdate +%s.%N);./D2J /Volumes/GITHUB/pipedicom/3.Ejecutables/converters/Formats/D/FluroWithDisplayShutter.dcm | ./J2D > /Users/Shared/a.dcm; export stop=$(gdate +%s.%N); echo "$stop - $start" | bc
.041595000
```
In our tests, our toolkit for the round trip to and from JSON is near ten times faster.


## Parsing from DICOM to NSXML
Alternatively, the framework DCKV also provides a parser directly to NSXMLElement of the objective-C lenguage including the aplication of n XSLT stylesheets. The final results of these transformations can be any media type of an XSLT output, including our "J" JSON output, and an opcional additional step converting JSON 2 a final DICOM result


