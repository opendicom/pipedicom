<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet  
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:dx="xmldicom.xsd" 
    xsi:schemaLocation="xmldicom.xsd 
    https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/xml/xmldicom.xsd"
    xml:space="default"
    >
    <xsl:output method="text" />
    
    <!-- ==============================================================================  -->
    <!-- contextualized key values dicom json "Marshalled" (organized) for serialization -->
    <!-- =============================================================================== -->
    
    <!-- 
{
 "bt~r":[]
 empty arrays for IQ (start of item), IZ (end of item), SZ (end of sequence)
    -->
    

    <!-- string functions -->
    
    <xsl:template name="extensionNumber">
        <xsl:param name="dotString"/>
        <xsl:choose>
            <xsl:when test="contains($dotString, '.')">
                <xsl:call-template name="extensionNumber">
                    <xsl:with-param name="dotString" select="substring-after($dotString, '.')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="number($dotString)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="removeExtension">
        <xsl:param name="dotString"/>
        <xsl:param name="first" select="true()"/>
        <xsl:if test="contains($dotString, '.')">
            <xsl:if test="not($first)">
                <xsl:text>.</xsl:text>
            </xsl:if>
            <xsl:value-of select="substring-before($dotString, '.')"/>
            <xsl:call-template name="removeExtension">
                <xsl:with-param name="dotString" select="substring-after($dotString, '.')"/>
                <xsl:with-param name="first" select="false()"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
       
    <!-- ordered list -->
    
    <xsl:variable name="branchTagList">
        <xsl:for-each select="/dx:dataset/dx:a">
            <xsl:element name="dx:a">
                <xsl:copy-of select="@b"/>
                <!-- 
                <xsl:copy-of select="@t"/>
                 -->
                <xsl:copy-of select="@r"/>
                <xsl:attribute name="bt">
                    <xsl:call-template name="branchTag">
                        <xsl:with-param name="b" select="@b"/>
                        <xsl:with-param name="t" select="@t"/>
                    </xsl:call-template>                    
                </xsl:attribute> 
                <xsl:copy-of select="*"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:template name="branchTag">
        <xsl:param name="b"/>
        <xsl:param name="t"/>
        <xsl:choose>
            <xsl:when test="contains($b, '.')">
                <xsl:value-of select="concat(substring-before($b, '.'),'-',substring-before($t, '.'),'.')"/>
                <xsl:call-template name="branchTag">
                    <xsl:with-param name="b" select="substring-after($b, '.')"/>
                    <xsl:with-param name="t" select="substring-after($t, '.')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat($b,'-',$t)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:variable name="list">
        <xsl:for-each select="$branchTagList/dx:a">
            <xsl:sort select="@bt" data-type="text" order="ascending"/>
            <xsl:element name="dx:a">
                <xsl:copy-of select="@bt"/>                
                <xsl:attribute name="vr">
                    <xsl:value-of select="@r"/>
                </xsl:attribute>
                <xsl:attribute name="parent">
                    <xsl:call-template name="removeExtension">
                        <xsl:with-param name="dotString" select="@bt"/>
                    </xsl:call-template>
                </xsl:attribute>
                <xsl:attribute name="item">
                    <xsl:call-template name="extensionNumber">
                        <xsl:with-param name="dotString" select="@b"/>
                    </xsl:call-template>
                </xsl:attribute>
                <xsl:attribute name="level">
                    <xsl:value-of select="string-length(@b) - string-length(translate(@b, '.',''))"/>
                </xsl:attribute>
                <xsl:copy-of select="*"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:variable>
    


    <!-- root template -->
    
    <xsl:template match="/dx:dataset">
        <xsl:text>{</xsl:text>
            <xsl:apply-templates select="$list/dx:a[@level=0][1]" mode="dataset">
                <xsl:with-param name="comma" select="false()"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="$list/dx:a[@level=0][position() > 1]" mode="dataset"/>
        <xsl:text>}</xsl:text>
    </xsl:template>
    
    
    <!-- attributes, items and values -->
    
    <xsl:template match="dx:a[@vr='SQ']" mode="dataset">
        <!-- separator? -->        
        <xsl:param name="comma" select="true()"/>
        <xsl:if test="$comma">
            <xsl:text>,</xsl:text>
        </xsl:if>
        <!-- dicom attribute -->
        <xsl:value-of select="concat('&quot;',@bt,'~SQ&quot;:[]')"/>
        <!-- contents -->
        <xsl:variable name="SQrootBt" select="@bt"/>
        <xsl:variable name="SQelements" select="$list/dx:a[@parent=$SQrootBt]"/>
        <!-- SQelements looses the dx: namespace.... do not  know why ??? -->
        <xsl:apply-templates select="$SQelements[not(@parent=preceding-sibling::a[1]/@parent)]" mode="item">
            <xsl:with-param name="SQelements" select="$SQelements"/>
        </xsl:apply-templates>                         
        
        <xsl:value-of select="concat(',&quot;',@bt,'.FFFEE0DD-00000000~SZ&quot;:[]')"/>
    </xsl:template>


    <xsl:template match="dx:a" mode="dataset">
        <!-- separator? -->        
        <xsl:param name="comma" select="true()"/>
        <xsl:if test="$comma">
            <xsl:text>,</xsl:text>
        </xsl:if>
        <!-- dicom attribute -->
        <xsl:value-of select="concat('&quot;',@bt,'~',@vr,'&quot;:[')"/>
        <xsl:apply-templates select="*"/><!-- values -->
        <xsl:text>]</xsl:text>        
    </xsl:template>
    
    
    <xsl:template match="dx:a" mode="item">
        <xsl:param name="SQelements"/>
        <xsl:variable name="itemRoot" select="substring(@bt,1,string-length(@bt)-8)"/>
        <!-- item start -->
        <xsl:value-of select="concat(',&quot;',$itemRoot,'00000000~IQ&quot;:[]')"/><!-- FFFEE000 -->
        <!-- item contents -->        
        <xsl:variable name="itemIndex" select="@item"/>
        <xsl:if test="@vr != 'IQ'"><!-- empty item -->
            <xsl:apply-templates select="$SQelements[@item=$itemIndex]" mode="dataset"/>
        </xsl:if>        
        <!-- item end -->
        <xsl:value-of select="concat(',&quot;',$itemRoot,'FFFEE00D~IZ&quot;:[]')"/>
    </xsl:template>


    <xsl:template match="dx:AE|dx:AS|dx:AT|dx:CS|dx:DA|dx:DS|dx:DT|dx:IS|dx:LO|dx:LT|dx:SH|dx:ST|dx:SV|dx:TM|dx:UC|dx:UI|dx:UR|dx:UT|dx:UV"><!-- string -->
        <xsl:if test="position() != 1">
            <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:value-of select="concat('&quot;',text(),'&quot;')"/>
    </xsl:template>


    <xsl:template match="dx:FL|dx:FD|dx:SL|dx:SS|dx:UL|dx:US"><!-- number -->
        <xsl:if test="position() != 1">
            <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:value-of select="text()"/>
    </xsl:template>


    <xsl:template match="dx:OB|dx:OD|dx:OF|dx:OL|dx:OV|dx:OW|dx:UN"><!-- base64 -->
        <xsl:if test="position() != 1">
            <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:value-of select="concat('&quot;',text(),'&quot;')"/>
    </xsl:template>


    <xsl:template match="dx:PN"><!-- person name -->
        <xsl:if test="position() != 1">
            <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:value-of select="concat('&quot;',text(),'&quot;')"/>
    </xsl:template>

</xsl:stylesheet>