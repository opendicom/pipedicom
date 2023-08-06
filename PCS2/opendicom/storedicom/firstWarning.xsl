<?xml version="1.0" encoding="UTF-8"?>

<!--
 00081190 RetrieveURL
 00081198 FailedSOPSequence
          00081150 ReferencedSOPClassUID
          00081155 ReferencedSOPInstanceUID
          00081197 FailureReason
 00081199 ReferencedSopSequence
          00081150 ReferencedSOPClassUID
          00081155 ReferencedSOPInstanceUID
          00081190 RetrieveURL
          00081196 WarningReason
          04000561 OriginalAttributesSequence
                   04000550 ModifiedAttributesSequence
                            ...
                   04000562 AttributeModificationDateTime
                   04000563 ModifyingSystem
                   04000564 SourceOfPreviousValues
-->

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    >
    
    <xsl:output encoding="UTF-8" media-type="text/plain" omit-xml-declaration="yes"/>
   
    <xsl:template match="/NativeDicomModel">
    	  <xsl:apply-templates select="DicomAttribute[@tag='00081199']/item[1]"/>
    			<!-- the same information is repeated for each of the instances of the series. We copy the first only -->
    </xsl:template>
    
    <xsl:template match="item">
    	  <xsl:value-of select="DicomAttribute[@tag='00081196']"/>
    			<xsl:text>\rOriginal sequence:\r</xsl:text>
    	  <xsl:apply-templates select="DicomAttribute[@tag='04000561']"/>
    	  <xsl:text>\r</xsl:text>
    </xsl:template>
	
	<!-- IdentityTransform (for items of 04000561) -->
    <xsl:template match="@* | node()">
      <xsl:copy>
         <xsl:apply-templates select="@* | node()" />
      </xsl:copy>
    </xsl:template>
		
</xsl:stylesheet>
