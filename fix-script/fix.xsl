<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cmdi="http://www.clarin.eu/cmd/"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:oai="http://www.openarchives.org/OAI/2.0/"
    exclude-result-prefixes="xs oai"
    version="2.0">
    <xsl:output encoding="UTF-8" omit-xml-declaration="yes"/>

    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@xsi:schemaLocation">
        <xsl:choose>
            <xsl:when test="count(tokenize(.,'\s+')) eq 1">
                <!-- FIX: refer to the right profile XSD -->
                <xsl:variable name="xsd">
                    <xsl:choose>
                        <xsl:when test="/cmdi:CMD/cmdi:Header/cmdi:MdProfile=('clarin.eu:cr1:p_1345561703673') and exists(/cmdi:CMD/cmdi:Components/*:DcmiTerms)">
                            <xsl:sequence select="'http://catalog.clarin.eu/ds/ComponentRegistry/rest/registry/profiles/clarin.eu:cr1:p_1288172614023/xsd'"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="string(.)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <!-- FIX: add the CMDI namespace URI -->
                <xsl:attribute name="xsi:schemaLocation" select="concat('http://www.clarin.eu/cmd/ ',$xsd)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="cmdi:Header">
        <xsl:copy>
            <!-- FIX: put the header fields in the right order -->
            <xsl:apply-templates select="cmdi:MdCreator"/>
            <xsl:apply-templates select="cmdi:MdCreationDate"/>
            <xsl:apply-templates select="cmdi:MdSelfLink"/>
            <xsl:apply-templates select="cmdi:MdProfile"/>
            <xsl:apply-templates select="cmdi:MdCollectionDisplayName"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="MdProfile">
        <xsl:copy>
            <xsl:choose>
                <!-- FIX: refer to the right profile -->
                <xsl:when test=".=('clarin.eu:cr1:p_1345561703673') and exists(/cmdi:CMD/cmdi:Components/*:DcmiTerms)">
                    <xsl:text>clarin.eu:cr1:p_1288172614023</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="cmdi:ResourceProxyList">
        <xsl:copy>
            <xsl:choose>
                <xsl:when test="exists(/cmdi:CMD/cmdi:Components/oai:DcmiTerms/oai:identifier)">
                    <!-- ENRICH: make the identifier a resource proxy of type LandingPage -->
                    <cmdi:ResourceProxy id="r1">
                        <cmdi:ResourceType>LandingPage</cmdi:ResourceType>
                        <cmdi:ResourceRef>
                            <xsl:choose>
                                <xsl:when test="/cmdi:CMD/cmdi:Header/cmdi:MdCollectionDisplayName='WomenWriters documents'">
                                    <xsl:value-of select="replace(/cmdi:CMD/cmdi:Components/oai:DcmiTerms/oai:identifier,'womenwriters','womenwriters/vre')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="/cmdi:CMD/cmdi:Components/oai:DcmiTerms/oai:identifier"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </cmdi:ResourceRef>
                    </cmdi:ResourceProxy>
                </xsl:when>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[namespace-uri()!='http://www.clarin.eu/cmd/']" priority="1">
        <!-- FIX: all elements should be in the CMDI namespace -->
        <xsl:element name="cmdi:{local-name()}">
            <xsl:apply-templates select="node() | @*"/>
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>
