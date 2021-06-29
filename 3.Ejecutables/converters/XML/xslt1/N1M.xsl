<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet  
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    version="1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns="xmldicom.xsd"
    extension-element-prefixes="exsl"
    xml:space="default"
    >
    
    <xsl:output method="xml" />

    <!-- 
defines default namespace and prefixed namespace "dx:" as "xmldicom.xsd" 
in order to allow validation of the result
    -->
    
    <!-- 
The extension exsl required for multiple node-set in the element dataset
http://exslt.org/exsl/index.html 
    -->
    
    <!-- 
In XSLT 1.0 the only way you can create namespace nodes dynamically in the most general case is by 
- constructing a dummy element in the relevant namespace 
- and then using <xsl:copy-of select="exslt:node-set($dummy)//namespace::x"/> to copy its namespace nodes. 
But this is very rarely necessary. 
    
https://stackoverflow.com/questions/46894126/xslt-1-0-how-to-keep-namespace-declaration-at-root
    -->
    
    <xsl:variable name="dummy">
        <dummy xmlns:dx="xmldicom.xsd"/>
    </xsl:variable>
    
    <!-- =================================================== -->
    <!-- contextualized key values xml from native dicom xml -->
    <!-- =================================================== -->
    
    <xsl:template match="/NativeDicomModel">
        <xsl:element name="dataset">
            <xsl:copy-of select="exsl:node-set($dummy)//namespace::*"/>
            <xsl:apply-templates select="DicomAttribute">
                <xsl:with-param name="branch" select="1"/>
                <xsl:with-param name="tagchain" select="''"/>
            </xsl:apply-templates>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="DicomAttribute">
        <xsl:param name="branch"/>
        <xsl:param name="tagchain"/>

        <xsl:variable name="newTagchain">
            <xsl:if test="string-length($tagchain)>0">
                <xsl:value-of select="$tagchain"/>
                <xsl:text>.</xsl:text>
            </xsl:if>
            <xsl:value-of select="@tag"/>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="@vr='SQ'">
                <xsl:element name="a">
                    <xsl:attribute name="b">
                        <xsl:value-of select="$branch"/>
                    </xsl:attribute>
                    <xsl:attribute name="t">
                        <xsl:value-of select="$newTagchain"/>
                    </xsl:attribute>
                    <xsl:attribute name="r">
                        <xsl:value-of select="@vr"/>
                    </xsl:attribute>
                </xsl:element>
                <xsl:apply-templates select="Item">
                    <xsl:with-param name="branch" select="$branch"/>
                    <xsl:with-param name="tagchain" select="$newTagchain"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="a">
                    <xsl:attribute name="b">
                        <xsl:value-of select="$branch"/>
                    </xsl:attribute>
                    <xsl:attribute name="t">
                        <xsl:value-of select="$newTagchain"/>
                    </xsl:attribute>
                    <xsl:attribute name="r">
                        <xsl:value-of select="@vr"/>
                    </xsl:attribute>
                    <xsl:choose>
                        <xsl:when test="@vr='PN'">
                            <xsl:apply-templates select="PersonName"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="Value">
                                <xsl:with-param name="vr" select="@vr"/>
                            </xsl:apply-templates>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="Value">
        <xsl:param name="vr"/>
        <xsl:element name="{$vr}">
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="PersonName">
        <xsl:element name="PN">
            <xsl:apply-templates select="Alphabetic"/>
            <xsl:if test="Ideographic | Phonetic">
                <xsl:text>=</xsl:text>
                <xsl:apply-templates select="Ideographic"/>
                <xsl:if test="Phonetic">
                    <xsl:text>=</xsl:text>
                    <xsl:apply-templates select="Phonetic"/>
                </xsl:if>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    

    <xsl:template match="Alphabetic | Ideographic | Phonetic">
        <xsl:value-of select="FamilyName/text()"/>
        <xsl:if test="GivenName | MiddleName | NamePrefix | NameSuffix">
            <xsl:text>^</xsl:text>
            <xsl:value-of select="GivenName/text()"/>
            <xsl:if test="MiddleName | NamePrefix | NameSuffix">
                <xsl:text>^</xsl:text>
                <xsl:value-of select="MiddleName/text()"/>
                <xsl:if test="NamePrefix | NameSuffix">
                    <xsl:text>^</xsl:text>
                    <xsl:value-of select="NamePrefix/text()"/>
                    <xsl:if test="NameSuffix">
                        <xsl:text>^</xsl:text>
                        <xsl:value-of select="NameSuffix/text()"/>
                    </xsl:if>
                </xsl:if>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <xsl:template match="Item">
        <xsl:param name="branch"/>
        <xsl:param name="tagchain"/>
        
        <xsl:choose>
            <xsl:when test="not(DicomAttribute)">
                <xsl:element name="a">
                    <xsl:attribute name="b">
                        <xsl:value-of select="$branch"/>
                        <xsl:text>.</xsl:text>
                        <xsl:value-of select="position()"/>
                    </xsl:attribute>
                    <xsl:attribute name="t">
                        <xsl:value-of select="$tagchain"/>
                        <xsl:text>.</xsl:text>
                    </xsl:attribute>
                    <xsl:attribute name="r"/>                                        
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="DicomAttribute">
                    <xsl:with-param name="branch">
                        <xsl:value-of select="$branch"/>
                        <xsl:text>.</xsl:text>
                        <xsl:value-of select="position()"/>
                    </xsl:with-param>
                    <xsl:with-param name="tagchain" select="$tagchain"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
        
</xsl:stylesheet>