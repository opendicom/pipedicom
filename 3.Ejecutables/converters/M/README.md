# mapxmldicom (M) and extensions

mapxmldicom (M) in the form of a XPath 3.1 explorable working XML DOM is our fundamental parsing result target.
It may be processed with textual tools other than XPath 3.1 when serialized into XML text or XML JSON.

- M.xml is an example of the XML text serialization
- M.xsd is the schema which validates the structure of the XML text serialization
- schema-for-json.xsd is the official validation schema for the node to be passed as first argument of the function xml-to-json(). Our M.xsd is a restriction of this schema
- M2J.xsl is a simple conversion of the XML text serialization to the JSON one. It is using esentially one XSLT 3 command only, xml-to-json() 

## mapxmldicom (M) and native (N) xml representation

The current official representation of DICOM in XML is the "Native" one. We copied N.xsd and N.rng which validate  XML objects. XML native was created as an intermediary, a means of describing native binary encoded DICOM objects as XML Infosets, thus allowing one to manipulate binary DICOM objects using familiar XML tools. As such, the schema is designed to facilitate a simple, mechanical, bi-directional translation between binary encoded DICOM and XML-like constructs without constraints, and to simplify identifying portions of a DICOM object using XPath statements.

### native

Be believe that Native here has the meaning defined in __[part 5 chapter 8.2 Native or Encapsulated Format Encoding](http://dicom.nema.org/medical/dicom/current/output/html/part05.html#sect_8.2)__ which states: "Pixel data conveyed in the Pixel Data (7FE0,0010) may be sent either in a Native (uncompressed) Format or in an Encapsulated Format (e.g., compressed) defined outside the DICOM Standard."

In mapxmldicom we overcome this limitation and accept also __[Encapsulated Format Encodings](http://dicom.nema.org/medical/dicom/current/output/html/part05.html#sect_A.4)__ for Pixel data. Our model accepts two variants: inlined encoded base64 and by reference. In the __[tree](https://github.com/jacquesfauquex/DICOM_contextualizedKey-values/tree/master/mapxmldicom)__:
- the variant "inlined" uses objects <string3> fo reach of the fragments within <array2>
- the variant "by reference" keeps the varios URLs in objects <string5> clasified into an <array4>
  
### simple, mechanical, bi-directional translation between M and N

The translation of datasets between N and M is performed by:
- M2N.xsl
- N2M.xsl

As far as M2N is concerned, it is posible to apply it within our parser directly on the DOM before serialization.

Using N2M.xsl as the first pass of a series of transformations allows as to uss then M2J.xsl or M2G.xsl on the intermediate result and obtain a JSON mapxmldicom object (J) or an official DICOM JSON (G) one as the final result.






