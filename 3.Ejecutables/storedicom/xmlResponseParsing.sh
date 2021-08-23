#!/bin/sh
STORERESP=$(cat $1)
REFERENCEDSOPSQ=$(echo $STORERESP |  tr '\12' '\40' | sed 's/.*00081199\" vr=\"SQ\">//')
REFERENCEDSOPSQ='<?xml version="1.0" encoding="UTF-8"?><NativeDicomModel xml-space="preserved"><DicomAttribute keyword="ReferencedSOPSequence" tag="00081199" vr="SQ">'$REFERENCEDSOPSQ

NOREFERENCEDSOPSQ=$(echo $STORERESP |  tr '\12' '\40' | sed 's/<DicomAttribute.keyword="ReferencedSOPSequence".tag="00081199.*//')
FAILEDSOPSQ=$(echo $NOREFERENCEDSOPSQ | sed 's/.*"00081198//')
FAILEDSOPSQ='<?xml version="1.0" encoding="UTF-8"?><NativeDicomModel xml-space="preserved"><DicomAttribute keyword="FailedSOPSequence" tag="00081198'$FAILEDSOPSQ'</NativeDicomModel>'

RESULT=$FAILEDSOPSQ
#RESULT=$NOREFERENCEDSOPSQ
#RESULT=$FAILEDSOPSQ
echo $RESULT