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

Three alternative blob modes are implemented:
- DinlineJ: the attributes contain blobs coded base64 within a string. This executable is designed for pipeline use. It reads from stdin and writes to stdout.
- DsourceJ: json attributes contain an url pointing at a subarray of bytes within the original dicom file. In this case the executable has one argument, the file path (which it uses as the base of the references). It does not read from stdin. It writes to stdout.
- D2: full fledged executable which reads a batch of files referenced to in paths to files and folders passed as arguments. The result mimics the subpaths in an outputFolder where it writes for each file.dcm its file.json counterpart and a folder file.bulkdata/ containing files for each of the blobs larger than a predefined size. The JSON contains relative paths to these files within file.bulkdata/


## optional conversion native explicit little endian to j2k enclosed

D2 has an option for j2k conversion of native explicit little endian file.dcm applied before outputing the file.json and file.bulkdata






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
