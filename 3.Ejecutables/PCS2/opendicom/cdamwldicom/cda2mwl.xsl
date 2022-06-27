<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema">
        
    <xsl:output encoding="UTF-8" media-type="text" omit-xml-declaration="yes" indent="no"/>
    
    <!-- ========================== date conversions ======================= -->
    
    <xsl:template name="isoDT2dcmDA">
        <xsl:param name="isoDT"/>
        <xsl:value-of select="substring($isoDT,1,4)"/>
        <xsl:value-of select="substring($isoDT,6,2)"/>
        <xsl:value-of select="substring($isoDT,9,2)"/>
    </xsl:template>
    
    <xsl:template name="isoDT2dcmTM">
        <xsl:param name="isoDT"/>
        <xsl:value-of select="substring($isoDT,12,2)"/>
        <xsl:value-of select="substring($isoDT,15,2)"/>
        <xsl:value-of select="substring($isoDT,18,2)"/>
    </xsl:template>
    
    
    <xsl:template name="nextKeyValue">
        <xsl:param name="key"/>
        <xsl:param name="value"/>
        <xsl:text>, "</xsl:text>
        <xsl:value-of select="$key"/>
        <xsl:text>" : [ "</xsl:text>
        <xsl:value-of select="$value"/>
        <xsl:text>" ]</xsl:text>
    </xsl:template>
    
    
    <!-- ===========================starting point =============================-->
    
    <xsl:template match="/cita">
        
        <!-- prolog -->
        <xsl:text>{ "metadata": { "00000001_0002002-UI" : [ "1.2.840.10008.5.1.4.31" ]</xsl:text>
        
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_0002003-UI</xsl:with-param>
            <xsl:with-param name="value"><xsl:value-of select="concat(@pkStudyUID,'.0')"/></xsl:with-param>
        </xsl:call-template>
        
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_0002010-UI</xsl:with-param>
            <xsl:with-param name="value">1.2.840.10008.1.2.1</xsl:with-param>
        </xsl:call-template>
        
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_0002012-UI</xsl:with-param>
            <xsl:with-param name="value">1.3.6.1.4.1.23650</xsl:with-param>
        </xsl:call-template>
        
        
       
        <xsl:text>}, "dataset": { "00000001_00080005-CS": [ "ISO_IR 100" ] </xsl:text>
 
 
        <!-- OBR-18 AccessionNumber-->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00080050-SH</xsl:with-param>
            <xsl:with-param name="value" select="@solicNumero"/>
        </xsl:call-template>
                
        <!-- ReferencedStudySequence -->
        <xsl:text>, "00000001_00081110-SQ": null, "00000001_00081110.FFFFFFFF_FFFEE0DD-SZ": null </xsl:text>
         
        
        <!-- ReferencedPatientSequence -->
        <xsl:text>, "00000001_00081120-SQ": null, "00000001_00081120.FFFFFFFF_FFFEE0DD-SZ": null </xsl:text>


        <!-- PID-5 PatientName -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00100010-PN</xsl:with-param>
            <xsl:with-param name="value">
                <xsl:value-of select="@apellido1"/>
                <xsl:if test="@apellido2 != ''">
                    <xsl:text disable-output-escaping="yes"> </xsl:text>
                    <xsl:value-of select="@apellido2"/>
                </xsl:if>
                <xsl:text disable-output-escaping="yes">^</xsl:text>
                <xsl:value-of select="@nombres"/>
            </xsl:with-param>
        </xsl:call-template>
        
        
        <!-- PID-3 PatientID-->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00100020-LO</xsl:with-param>
            <xsl:with-param name="value" select="@id"/>
        </xsl:call-template>
        
        
        <!-- Patient ID issuer 
            (if it doesn't exist, 
            we create it form @id 
            as a possibly erroneous uruguayan cédula) 
        -->
        <xsl:choose>
            <xsl:when test="@fkOidP = ''">
                <xsl:call-template name="nextKeyValue">
                    <xsl:with-param name="key">00000001_00100021-LO</xsl:with-param>
                    <xsl:with-param name="value" select="concat('2.16.858.1.858.68909.',@id)"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="nextKeyValue">
                    <xsl:with-param name="key">00000001_00100021-LO</xsl:with-param>
                    <xsl:with-param name="value" select="@fkOidP"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        
        
        <!-- PID-7 birthdate -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00100030-DA</xsl:with-param>
            <xsl:with-param name="value">
                <xsl:call-template name="isoDT2dcmDA">
                    <xsl:with-param name="isoDT" select="@nacimiento"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
        
        
        <!-- PID-8 PatientSex -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00100040-CS</xsl:with-param>
            <xsl:with-param name="value" select="@sexo"/>
        </xsl:call-template>
        
        
        <!-- PatientAge
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00101010-AS</xsl:with-param>
            <xsl:with-param name="value">
            </xsl:with-param>
        </xsl:call-template>
         -->
        
        <!-- ZDS -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_0020000D-UI</xsl:with-param>
            <xsl:with-param name="value" select="@pkStudyUID"/>
        </xsl:call-template>
        
        <!-- ORC-17 OBR-16 Requesting Physician -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00321032-PN</xsl:with-param>
            <xsl:with-param name="value" select="concat(iSolicitante/@nombreCorto,'^',pSolicitante/@nombre)"/>            
        </xsl:call-template>


        <!-- OBR-4 RequestedProcedureDescription -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00321060-LO</xsl:with-param>
            <xsl:with-param name="value" select="procedimiento/@titulo"/>            
        </xsl:call-template>
        
        
        <!-- Scheduled Procedure Step Sequence -->
        <xsl:text>, "00000001_00400100-SQ": null</xsl:text>
        <!-- item 1 -->
        <xsl:text>, "00000001_00400100.00000001_00000000-IQ": null</xsl:text>
        
        <!-- Modality -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00400100.00000001_00080060-CS</xsl:with-param>
            <xsl:with-param name="value" select="procedimiento[1]/@fkModalidadDicom"/>
        </xsl:call-template>
        
        
        <!-- Scheduled Station AE Title -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00400100.00000001_00400001-AE</xsl:with-param>
            <xsl:with-param name="value" select="'UNKNOWN'"/>
        </xsl:call-template>
        
        
        <!-- OBR-27 = ORC-9 Scheduled Procedure Step Start Date -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00400100.00000001_00400002-DA</xsl:with-param>
            <xsl:with-param name="value">
                <xsl:call-template name="isoDT2dcmDA">
                    <xsl:with-param name="isoDT" select="@principio"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
        
        
        <!-- OBR-27 = ORC-9 Scheduled Procedure Step Start Time -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00400100.00000001_00400003-TM</xsl:with-param>
            <xsl:with-param name="value">
                <xsl:call-template name="isoDT2dcmTM">
                    <xsl:with-param name="isoDT" select="@principio"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
        
        
        <!-- OBR-20 Scheduled Procedure Step ID -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00400100.00000001_00400007-LO</xsl:with-param>
            <xsl:with-param name="value" select="procedimiento/@titulo"/>
        </xsl:call-template>


        <!-- OBR-20 Scheduled Procedure Step ID -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00400100.00000001_00400009-SH</xsl:with-param>
            <xsl:with-param name="value" select="procedimiento[1]/paso[1]/@pkPaso"/>
        </xsl:call-template>
        
        
        <!-- Scheduled Station Name -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00400100.00000001_00400010-SH</xsl:with-param>
            <xsl:with-param name="value" select="'UNKNOWN'"/>
        </xsl:call-template>
        
        
        <!-- Scheduled Procedure Step Status -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00400100.00000001_00400020-CS</xsl:with-param>
            <xsl:with-param name="value" select="'ARRIVED'"/>
        </xsl:call-template>
        
        
        <xsl:text>, "00000001_00400100.00000001_FFFEE00D-IZ": null</xsl:text>
        <xsl:text>, "00000001_00400100.FFFFFFFF_FFFEE0DD-SZ": null</xsl:text>
        
        
        <!-- OBR-19 Requested Procedure ID -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00401001-SH</xsl:with-param>
            <xsl:with-param name="value" select="substring(@pkStudyUID,string-length(@pkStudyUID)-15,16)"/>
        </xsl:call-template>
        
        
        <!-- Request Procedure Priority -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00401003-CS</xsl:with-param>
            <xsl:with-param name="value" select="'STAT'"/>
        </xsl:call-template>
        
        
        <!-- ORC-2 Placer Order Number / Imaging Service Request -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00402016-LO</xsl:with-param>
            <xsl:with-param name="value" select="substring(@pkStudyUID,string-length(@pkStudyUID)-15,16)"/>
        </xsl:call-template>
        
        
        <!-- OBR-20 Filler Order Number / Imaging Service Request -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001_00402017-LO</xsl:with-param>
            <xsl:with-param name="value" select="procedimiento[1]/paso[1]/@pkPaso"/>
        </xsl:call-template>
                 
        
        <xsl:text disable-output-escaping="yes"> } }</xsl:text>
    </xsl:template>
</xsl:stylesheet>
