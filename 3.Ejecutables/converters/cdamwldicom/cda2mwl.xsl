<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema">
    
    <xsl:param name="now">20210128120000</xsl:param>
    
    <xsl:output encoding="ISO-8859-1" media-type="text" omit-xml-declaration="yes" indent="no"/>
    
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

    <xsl:template name="isoDT2dcmDT">
        <xsl:param name="isoDT"/>
        <xsl:value-of select="substring($isoDT,1,4)"/>
        <xsl:value-of select="substring($isoDT,6,2)"/>
        <xsl:value-of select="substring($isoDT,9,2)"/>
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
        <xsl:text>{ "dataset": { "00000001-00080005_CS": [ "ISO_IR 100" ] </xsl:text>
        <xsl:variable name="nowDT" select="substring(string($now),1,14)"/>


        <!-- PID-5 PatientName -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001-00100010_1100PN</xsl:with-param>
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
            <xsl:with-param name="key">00000001-00100020_1100LO</xsl:with-param>
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
                    <xsl:with-param name="key">00000001-00100021_1100LO</xsl:with-param>
                    <xsl:with-param name="value" select="concat('2.16.858.1.858.68909.',@id)"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="nextKeyValue">
                    <xsl:with-param name="key">00000001-00100021_1100LO</xsl:with-param>
                    <xsl:with-param name="value" select="@fkOidP"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        

        <!-- PID-7 birthdate -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001-00100030_DA</xsl:with-param>
            <xsl:with-param name="value">
                <xsl:call-template name="isoDT2dcmDA">
                    <xsl:with-param name="isoDT" select="@nacimiento"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
        
        
        <!-- PID-8 PatientSex -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001-00100040_CS</xsl:with-param>
            <xsl:with-param name="value" select="@sexo"/>
        </xsl:call-template>
        
        
        <!-- PatientAge
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001-00101010_AS</xsl:with-param>
            <xsl:with-param name="value">
            </xsl:with-param>
        </xsl:call-template>
         -->
        
        <!-- ZDS -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001-0020000D_UI</xsl:with-param>
            <xsl:with-param name="value" select="@pkStudyUID"/>
        </xsl:call-template>
        
        <!-- ORC-17 OBR-16 Requesting Physician -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001-00321032_1100PN</xsl:with-param>
            <xsl:with-param name="value" select="concat(iSolicitante/@nombreCorto,'^',pSolicitante/@nombre)"/>            
        </xsl:call-template>

        
        <!-- Scheduled Procedure Step Sequence -->
        <xsl:text>, "00000001-00400100_SQ": null</xsl:text>
        <!-- item 1 -->
        <xsl:text>, "00000001-00400100.00000001-00000000_IQ": null</xsl:text>

        <!-- Modality -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001-00400100.00000001-00080060_CS</xsl:with-param>
            <xsl:with-param name="value" select="@fkModalidadDicom"/>
        </xsl:call-template>
 

        <!-- Scheduled Station AE Title -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001-00400100.00000001-00400001_AE</xsl:with-param>
            <xsl:with-param name="value" select="'UNKNOWN'"/>
        </xsl:call-template>
        
        
        <!-- OBR-27 = ORC-9 Scheduled Procedure Step Start Date -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001-00400100.00000001-00400002_DA</xsl:with-param>
            <xsl:with-param name="value">
                <xsl:call-template name="isoDT2dcmDA">
                    <xsl:with-param name="isoDT" select="$nowDT"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
        
        
        <!-- OBR-27 = ORC-9 Scheduled Procedure Step Start Time -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001-00400100.00000001-00400003_TM</xsl:with-param>
            <xsl:with-param name="value">
                <xsl:call-template name="isoDT2dcmTM">
                    <xsl:with-param name="isoDT" select="$nowDT"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
        
        
        <!-- OBR-20 Scheduled Procedure Step ID -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001-00400100.00000001-00400009_1100SH</xsl:with-param>
            <xsl:with-param name="value" select="@pkPaso"/>
        </xsl:call-template>
        
        
        <!-- Scheduled Station Name -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001-00400100.00000001-00400010_1100SH</xsl:with-param>
            <xsl:with-param name="value" select="'UNKNOWN'"/>
        </xsl:call-template>
        
        
        <!-- Scheduled Procedure Step Status -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001-00400100.00000001-00400020_CS</xsl:with-param>
            <xsl:with-param name="value" select="'ARRIVED'"/>
        </xsl:call-template>
        
        
        <xsl:text>, "00000001-00400100.00000001-FFFEE00D_IZ": null</xsl:text>
        <xsl:text>, "00000001-00400100.FFFFFFFF-FFFEE0DD_SZ": null</xsl:text>
        
        
        <!-- OBR-19 Requested Procedure ID -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001-00401001_1100SH</xsl:with-param>
            <xsl:with-param name="value" select="substring(@pkStudyUID,string-length(@pkStudyUID)-15,16)"/>
        </xsl:call-template>
        
        
        <!-- Request Procedure Priority -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001-00401003_CS</xsl:with-param>
            <xsl:with-param name="value" select="'STAT'"/>
        </xsl:call-template>
        
        
        <!-- ORC-2 Placer Order Number / Imaging Service Request -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001-00402016_1100LO</xsl:with-param>
            <xsl:with-param name="value" select="substring(@pkStudyUID,string-length(@pkStudyUID)-15,16)"/>
        </xsl:call-template>
        
        
        <!-- OBR-20 Filler Order Number / Imaging Service Request -->
        <xsl:call-template name="nextKeyValue">
            <xsl:with-param name="key">00000001-00402017_1100LO</xsl:with-param>
            <xsl:with-param name="value" select="@pkPaso"/>
        </xsl:call-template>



        <!-- ORC OBR pasos - variables
        
        <xsl:variable name="iSolicitante" select="iSolicitante/@nombreCorto"/> 
        
        <xsl:variable name="placerOrderNumber" select="substring(@pkStudyUID,string-length(@pkStudyUID)-15,16)"/>
        
        <xsl:variable name="studyTitle" select="procedimiento/@titulo"/>
        
        <xsl:variable name="medicoSolicitante" select="pSolicitante/@nombre"/>
        
        <xsl:variable name="accessionNumber" select="@solicNumero"/>
        
         -->
             
       <!-- ORC-17 Institución origen del paciente 
            <xsl:value-of select="$iSolicitante"/>
        -->
        
        
       <!-- OBR-4 código estudio
            <xsl:value-of select="$studyTitle"/>
        -->


       <!-- OBR-16 médico solicitante 
            <xsl:value-of select="$medicoSolicitante"/>
            <xsl:text disable-output-escaping="yes">||</xsl:text>
        -->
        
       <!-- OBR-18 access number
            <xsl:value-of select="$accessionNumber"/>
            <xsl:text disable-output-escaping="yes">|</xsl:text>
        -->

        <!-- epilog -->
        <xsl:text disable-output-escaping="yes"> } }</xsl:text>
    </xsl:template>
</xsl:stylesheet>
