<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:dx="xmldicom.xsd" 
    xsi:schemaLocation="xmldicom.xsd https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/xml/xmldicom.xsd">
    <xsl:output method="text"/>
    <xsl:template match="/dx:dataset">
        <xsl:text>{</xsl:text>
            <xsl:for-each select="dx:a">
                <xsl:if test="position()>1">
                    <xsl:text>,</xsl:text>
                </xsl:if>
                <xsl:value-of select="concat('&quot;',@b,'-',@t,'-',@r,'&quot;:[')"/>
                <xsl:choose>
                    <xsl:when test="@r='SS'">
                        <!-- number -->
                        <xsl:for-each select="*">
                            <xsl:if test="position()>1">
                                <xsl:text>,</xsl:text>
                            </xsl:if>
                            <xsl:value-of select="text()"/>                            
                        </xsl:for-each>                
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- string -->
                        <xsl:for-each select="*">
                            <xsl:if test="position()>1">
                                <xsl:text>,</xsl:text>
                            </xsl:if>                            
                            <xsl:text>&quot;</xsl:text>
                            <xsl:value-of select="text()"/>
                            <xsl:text>&quot;</xsl:text>                            
                        </xsl:for-each>                
                    </xsl:otherwise>
                </xsl:choose>
               <xsl:text>]</xsl:text>
            </xsl:for-each>
        <xsl:text>}</xsl:text>
    </xsl:template>
</xsl:stylesheet>