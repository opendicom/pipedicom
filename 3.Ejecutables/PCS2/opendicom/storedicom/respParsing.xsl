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
    <xsl:param name="qido">qido</xsl:param>    
    <xsl:param name="org">org</xsl:param>    
    <xsl:param name="branch">branch</xsl:param>
    <xsl:param name="device">device</xsl:param>
    <xsl:param name="euid">euid</xsl:param>
    <xsl:param name="suid">suid</xsl:param>
    <xsl:param name="logpath">logpath</xsl:param>
    <xsl:param name="logpathexists">FALSE</xsl:param>
    
    <xsl:template match="/NativeDicomModel">
        <xsl:if test="$logpathexists = 'FALSE'">
            <xsl:text>#!/bin/sh&#xA;</xsl:text>
            <xsl:text>#opendicom.storedicom.log&#xA;</xsl:text>
        </xsl:if>
        <xsl:variable name="RELATIVEURL" select="concat($branch,'/',$device,'/',$euid,'/',$suid)"/>
        <xsl:value-of select="concat('echo /Volumes/IN/',$org,'/SENT/',$RELATIVEURL,'/&#xA;')"/>

        <!-- 1. failed -->
        <xsl:variable name="failedCount" select="count(DicomAttribute[@keyword='FailedSOPSequence']/Item)"/>
        <xsl:if test="$failedCount > 0">
            
            <xsl:value-of select="concat('export LOGPATH=',$logpath,'/&#xA;')"/>
            <xsl:value-of select="concat('export SENTSERIES=/Volumes/IN/',$org,'/SENT/',$RELATIVEURL,'/&#xA;')"/>
            <xsl:value-of select="concat('export SENDSERIES=/Volumes/IN/',$org,'/SEND/',$RELATIVEURL,'/&#xA;')"/>
            <xsl:value-of select="concat('export QIDOENDPOINT=',$qido,'/&#xA;')"/>
            
            <xsl:variable name="keyword" select="normalize-space(//DicomAttribute[@keyword='FailureReason']/Value/text())"/>
            <xsl:choose>
                <xsl:when test="( $keyword >= 42752 ) and ( $keyword &lt;= 43007 )" >
                    <xsl:value-of select="concat('# ',$failedCount,' FAILED ',$keyword,': Refused out of Resources&#xA;')"/>
                </xsl:when>
                <xsl:when test="( $keyword >= 43264 ) and ( $keyword &lt;= 43519 )" >
                    <xsl:value-of select="concat('# ',$failedCount,' FAILED ',$keyword,': Error: Data Set does not match SOP Class&#xA;')"/>
                </xsl:when>
                <xsl:when test="( $keyword >= 49152 ) and ( $keyword &lt;= 53247 )" >
                    <xsl:value-of select="concat('# ',$failedCount,' FAILED ',$keyword,': Error: Duplicate or Cannot understand&#xA;')"/>
                    <xsl:text>/Users/Shared/opendicom/storedicom/recycle.sh /&#xA;</xsl:text>
                </xsl:when>
                <xsl:when test="$keyword = 49442" >
                    <xsl:value-of select="concat('# ',$failedCount,' FAILED ',$keyword,': Referenced Transfer Syntax not supported&#xA;')"/>
                </xsl:when>
                <xsl:when test="$keyword = 272" >
                    <xsl:value-of select="concat('# ',$failedCount,' FAILED ',$keyword,': Processing failure&#xA;')"/>
                </xsl:when>
                <xsl:when test="$keyword = 290" >
                    <xsl:value-of select="concat('# ',$failedCount,' FAILED ',$keyword,': Referenced SOP Class not supported&#xA;')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('# ',$failedCount,' FAILED ',$keyword,': ?&#xA;')"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="DicomAttribute[@keyword='FailedSOPSequence']/Item/DicomAttribute[@keyword='ReferencedSOPInstanceUID']/Value" mode="failure"/>
            <xsl:text>;&#xA;&#xA;</xsl:text>
        </xsl:if>
        
        <!-- 2. warning -->
        <xsl:variable name="warningCount" select="count(//DicomAttribute[@keyword='WarningReason'])"/>
        <xsl:if test="$warningCount > 0">
            <xsl:variable name="keyword" select="normalize-space(//DicomAttribute[@keyword='WarningReason']/Value/text())"/>
            <xsl:choose>
                <xsl:when test="$keyword = 45056" >
                    <xsl:value-of select="concat('# ',$warningCount,' WARNING ',$keyword,': Coercion of Data Elements&#xA;')"/>
                </xsl:when>
                <xsl:when test="$keyword = 45062" >
                    <xsl:value-of select="concat('# ',$warningCount,' WARNING ',$keyword,': Elements Discarded&#xA;')"/>
                </xsl:when>
                <xsl:when test="$keyword = 45063" >
                    <xsl:value-of select="concat('# ',$warningCount,' WARNING ',$keyword,': Data Set does not match SOP Class&#xA;')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('# ',$warningCount,' WARNING ',$keyword,': ?&#xA;')"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="DicomAttribute[@keyword='ReferencedSOPSequence']/Item[1]/DicomAttribute[@keyword='WarningReason'][1]/following-sibling::DicomAttribute[@keyword='OriginalAttributesSequence'][1]/Item[1]/DicomAttribute[1]/Item[1]" mode="warning"/>
            <xsl:text>&#xA;</xsl:text>
        </xsl:if>

        <!-- 3. referenced -->
        <xsl:variable name="referencedCount" select="count(DicomAttribute[@keyword='ReferencedSOPSequence']/Item)"/>
        <xsl:if test="$referencedCount > 0"><xsl:value-of select="concat('# REFERENCED ',$referencedCount,'&#xA;')"/></xsl:if>
        
        
    </xsl:template>
    
    
    <xsl:template match="Value" mode="failure">
        <xsl:value-of select="concat(text(),' \&#xA;')"/>
    </xsl:template>
    
    <xsl:template match="Item" mode="warning">
        <xsl:apply-templates select="DicomAttribute" mode="warning"/>
    </xsl:template>
    
    <xsl:template match="DicomAttribute" mode="warning">
        <xsl:value-of select="concat('# original ',@keyword,':',normalize-space(.),'&#xA;')"/>
    </xsl:template>
    
</xsl:stylesheet>
