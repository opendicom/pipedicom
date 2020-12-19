<?xml version="1.1" encoding="UTF-8"?>

<xsl:stylesheet 
    version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:dx="xmldicom.xsd"
    xpath-default-namespace="xmldicom.xsd"
    >
    
    <!-- remove attribute 00080070 -->
    <xsl:template match="a[@t='00080070']"/>
    
    <!-- remove first value of attribute 00080060 -->
    <xsl:template match="dx:a[@t='00080060']/*[1]"/>
    

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
         
    
</xsl:stylesheet>
