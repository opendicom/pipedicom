<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:dx="xmldicom.xsd" 
    xsi:schemaLocation="xmldicom.xsd https://raw.githubusercontent.com/jacquesfauquex/DICOM_contextualizedKey-values/master/xml/xmldicom.xsd">
    <xsl:output method="text"/>
    
    <xsl:variable name="list" select="/dx:dataset/*"/>
    <xsl:variable name="afterList" select="count($list) + 1"/>
    <xsl:variable name="number_r" select="'FL|FD|SL|SS|UL|US'"/>
    <xsl:variable name="person_r" select="'PN'"/>
    <xsl:variable name="base64_r" select="'OB|OD|OF|OL|OV|OW|UN'"/>
    <!--
    <xsl:variable name="sting_r" select="'AE|AS|AT|CS|DA|DS|DT|IS|LO|LT|SH|ST|SV|TM|UC|UI|UR|UT|UV'"/>
    <xsl:variable name="sequence_r" select="'SQ'"/>
    -->
    
    <xsl:template match="/dx:dataset">
        <xsl:text>{</xsl:text>
        <xsl:call-template name="next">
            <xsl:with-param name="index" select="1"/>
            <xsl:with-param name="previousBranch" select="1"/>
            <xsl:with-param name="previousLevel" select="0"/>
            <xsl:with-param name="previousVr" select="''"/>
        </xsl:call-template>
        <xsl:text>}</xsl:text>    
    </xsl:template>
    
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

    <!-- recursive -->
    <xsl:template name="next">
        <xsl:param name="index"/>
        <xsl:param name="previousBranch"/>
        <xsl:param name="previousLevel"/>
        <xsl:param name="previousVr"/>
        
        <xsl:choose>
            <xsl:when test="$index=$afterList">
                <xsl:choose>
                    <xsl:when test="$previousVr='SQ'"><!-- empty last SQ -->
                        <xsl:text>]</xsl:text>
                        <xsl:call-template name="next">
                            <xsl:with-param name="index" select="$afterList"/>
                            <xsl:with-param name="previousBranch" select="$previousBranch"/>
                            <xsl:with-param name="previousLevel" select="$previousLevel"/>
                            <xsl:with-param name="previousVr" select="'NULL'"/>
                        </xsl:call-template>               
                    </xsl:when>
                    <xsl:when test="$previousLevel>0"><!-- close open item and SQ -->
                        <xsl:text>}]</xsl:text>
                        <xsl:call-template name="next">
                            <xsl:with-param name="index" select="$afterList"/>
                            <xsl:with-param name="previousBranch" select="$previousBranch"/>
                            <xsl:with-param name="previousLevel" select="$previousLevel - 1"/>
                            <xsl:with-param name="previousVr" select="'NULL'"/>
                        </xsl:call-template>               
                    </xsl:when>                   
                    <!-- otherwise end of processing -->
                </xsl:choose>            
            </xsl:when>
            <xsl:otherwise>
                
                <xsl:variable name="a" select="$list[$index]"/>
                <xsl:variable name="newLevel" select="string-length($a/@b) - string-length(translate($a/@b, '.',''))"/>
                <xsl:choose>

                    <xsl:when test="($previousVr='SQ') and not($newLevel &gt; $previousLevel)"><!-- end empty SQ -->
                        <xsl:text>[]</xsl:text>
                        <xsl:call-template name="next">
                            <xsl:with-param name="index" select="$index"/>
                            <xsl:with-param name="previousBranch" select="$previousBranch"/>
                            <xsl:with-param name="previousLevel" select="$previousLevel"/>
                            <xsl:with-param name="previousVr" select="''"/>
                        </xsl:call-template>
                    </xsl:when>
                    
                    <xsl:when test="($previousVr='SQ')"><!-- SQ start -->
                        <xsl:text>{</xsl:text>
                        <xsl:call-template name="next">
                            <xsl:with-param name="index" select="$index"/>
                            <xsl:with-param name="previousBranch" select="$previousBranch"/>
                            <xsl:with-param name="previousLevel" select="$previousLevel"/>
                            <xsl:with-param name="previousVr" select="''"/>
                        </xsl:call-template>
                    </xsl:when>
                    
                    <xsl:when test="$previousLevel &gt; $newLevel"><!-- end item and SQ -->
                        <xsl:text>}]</xsl:text>
                        <xsl:call-template name="next">
                            <xsl:with-param name="index" select="$index"/>
                            <xsl:with-param name="previousBranch" select="$previousBranch"/>
                            <xsl:with-param name="previousLevel" select="$previousLevel - 1"/>
                            <xsl:with-param name="previousVr" select="$previousVr"/>
                        </xsl:call-template>                
                    </xsl:when>
                    
                    <xsl:when test="not($a/@b = $previousBranch)"><!-- next new item? -->                         
                        <!-- greater last number? -->
                        <xsl:variable name="cbExtensionInt">
                            <xsl:call-template name="extensionNumber">
                                <xsl:with-param name="dotString" select="$a/@b"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="pbExtensionInt">
                            <xsl:call-template name="extensionNumber">
                                <xsl:with-param name="dotString" select="$previousBranch"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="(string-length($a/@b) = string-length($previousBranch)) and ($cbExtensionInt = $pbExtensionInt + 1)">
                                <xsl:text>},{</xsl:text>
                            </xsl:when>
                            <xsl:otherwise><xsl:text>ERROR: item lacking</xsl:text></xsl:otherwise>
                        </xsl:choose>
                        
                        <xsl:call-template name="next">
                            <xsl:with-param name="index" select="$index"/>
                            <xsl:with-param name="previousBranch" select="$a/@b"/>
                            <xsl:with-param name="previousLevel" select="$newLevel"/>
                            <xsl:with-param name="previousVr" select="''"/>
                        </xsl:call-template>
                    </xsl:when>
                                       
                    <xsl:otherwise>
                        <xsl:if test="not($previousVr='')">
                            <xsl:text>,</xsl:text>
                        </xsl:if>
                        <xsl:value-of select="concat('&quot;',substring($a/@t,string-length($a/@t) - 7,8),'&quot;:{&quot;vr&quot;:&quot;',$a/@r,'&quot;,&quot;Value&quot;:[')"/>
                        <xsl:choose>
                            
                            <xsl:when test="$a/@r = 'SQ'">
                            </xsl:when>

                            <xsl:when test="contains($number_r , $a/@r)">
                                <xsl:for-each select="$a/*">
                                    <xsl:if test="position()>1">
                                        <xsl:text>,</xsl:text>
                                    </xsl:if>                            
                                    <xsl:value-of select="text()"/>
                                </xsl:for-each>                               
                                <xsl:text>]}</xsl:text>
                            </xsl:when>
                            
                            <xsl:when test="contains($person_r,$a/@r)">
                                <xsl:for-each select="$a/*">
                                    <xsl:if test="position()>1">
                                        <xsl:text>,</xsl:text>
                                    </xsl:if>                            
                                    <xsl:value-of select="concat('{&quot;Alphabetic&quot;:&quot;',text(),'&quot;}')"/>
                                </xsl:for-each>                               
                                <xsl:text>]}</xsl:text>
                            </xsl:when>
                            
                            <xsl:when test="contains($base64_r,$a/@r)">
                                <xsl:for-each select="$a/*">
                                    <xsl:if test="position()>1">
                                        <xsl:text>,</xsl:text>
                                    </xsl:if>                            
                                    <xsl:value-of select="concat('&quot;',text(),'&quot;')"/>
                                </xsl:for-each>                               
                                <xsl:text>]}</xsl:text>
                            </xsl:when>
                                                            
                            <xsl:otherwise><!-- $string_r -->
                                <xsl:for-each select="$a/*">
                                    <xsl:if test="position()>1">
                                        <xsl:text>,</xsl:text>
                                    </xsl:if>                            
                                    <xsl:value-of select="concat('&quot;',text(),'&quot;')"/>
                                </xsl:for-each>
                                <xsl:text>]}</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>

                        <xsl:call-template name="next">
                            <xsl:with-param name="index" select="$index + 1"/>
                            <xsl:with-param name="previousBranch" select="$a/@b"/>
                            <xsl:with-param name="previousLevel" select="$newLevel"/>
                            <xsl:with-param name="previousVr" select="$a/@r"/>
                        </xsl:call-template>
                        
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>            
        </xsl:choose>        
    </xsl:template>
        
</xsl:stylesheet>