<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:l="http://language.data">
    <xsl:output indent="yes" />
    <xsl:variable name="urlbase" select="string('https://doi.org/')" />
    
    <xsl:template match='/'>
        
        <xsl:for-each select="/response/result">
            <add>
                <!--                 <xsl:for-each select="doc"> -->
                <xsl:for-each select="doc">
                <xsl:sort select="arr[@name='dc.identifier']/str/text()" data-type="text" order="ascending"/>
                <doc>
                    <field name="id"><xsl:value-of select="concat('ds_', str[@name='handle']/text())" /></field>
                    <field name="libraoc_id"><xsl:value-of select="concat('oc_', arr[@name='dc.identifier']/str/text())" /></field>
                <!--             <field name="digital_collection_f_stored">Libra Repository</field>  -->
                <field name="doc_type_f_stored">libra</field>
                <!--              <field name="source_facet">Libra2 Repository</field> -->
                <field name="source_f_stored">Libra Repository</field>
                <field name="digital_collection_f_stored">Libra Open Repository</field>
                <field name="data_source_f_stored">librads</field>
                <field name="pool_f_stored">thesis</field>
                <field name="location_f_stored">Internet Materials</field>
                <field name="shadowed_location_f_stored">
                    <xsl:choose>
                        <xsl:when test="str[@name='discoverable'] = 'true' or str[@name='withdrawn'] != 'false'">
                            <xsl:text>VISIBLE</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>HIDDEN</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </field>
                <field name="uva_availability_f_stored">Online</field>
                <field name="anon_availability_f_stored">Online</field>
                    <xsl:if test="arr[@name='dateIssued']/str != ''">
                    <xsl:call-template name="fixDate">
                        <xsl:with-param name="field">published_daterange</xsl:with-param>
                        <xsl:with-param name="datestring"><xsl:value-of select="arr[@name='dateIssued']/str" /></xsl:with-param>
                        <xsl:with-param name="range">true</xsl:with-param>
                    </xsl:call-template>
                    <xsl:call-template name="fixDate">
                        <xsl:with-param name="field">published_display_a</xsl:with-param>
                        <xsl:with-param name="datestring"><xsl:value-of select="arr[@name='dateIssued']/str" /></xsl:with-param>
                        <xsl:with-param name="range">true</xsl:with-param>
                    </xsl:call-template>
                    <xsl:call-template name="fixDate">
                        <xsl:with-param name="field">published_date</xsl:with-param>
                        <xsl:with-param name="datestring"><xsl:value-of select="arr[@name='dateIssued']/str" /></xsl:with-param>
                        <xsl:with-param name="monthDefault">-01</xsl:with-param>
                        <xsl:with-param name="dayDefault">-01</xsl:with-param>
                        <xsl:with-param name="timeDefault">T00:00:00Z</xsl:with-param>
                    </xsl:call-template>
                </xsl:if>
                <field name="published_tsearch_stored">
                    <xsl:call-template name="publisherinfo"/>
                </field> 
                <field name="title_tsearch_stored"><xsl:value-of select="arr[@name='title']/str[1]" /></field>
                <field name="title_ssort_stored"><xsl:call-template name="cleantitle" >
                    <xsl:with-param name="title" select="arr[@name='title']/str[1]"/>
                    <xsl:with-param name="language" select="arr[@name='dc.language']/str"/>
                    </xsl:call-template></field>
                <xsl:for-each select="arr[@name='mods_journal_title_info_t']">
                    <field name="journal_title_tsearch_stored">
                        <xsl:value-of select="str" />
                    </field>
                </xsl:for-each> 
                <field name="work_title2_key_ssort_stored">
                    <xsl:variable name="title">
                        <xsl:call-template name="cleantitle" >
                            <xsl:with-param name="title" select="arr[@name='title']/str[1]"/>
                            <xsl:with-param name="language" select="arr[@name='dc.language']/str"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:variable name="author">
                        <xsl:value-of select="arr[@name='author']/str[1]"/>
                    </xsl:variable>
                    <xsl:variable name="format">
                        <xsl:call-template name="getformat" />
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="contains($author, ', ')" >
                            <xsl:variable name="firstName">
                                <xsl:value-of select="substring-after($author, ', ')"/>
                            </xsl:variable>
                            <xsl:variable name="lastName">
                                <xsl:value-of select="substring-before($author, ', ')"/>
                            </xsl:variable>
                            <xsl:value-of select="replace(lower-case($title), '[- ]+', '_')"/><xsl:text>/</xsl:text><xsl:value-of select="replace(lower-case($lastName),'[ ]+','_')"/>
                            <xsl:text>_</xsl:text><xsl:value-of select="replace(lower-case($firstName),'[ ]+','_')"/><xsl:value-of select="concat('/', $format)"/>
                       </xsl:when>
                       <xsl:otherwise>
                            <xsl:value-of select="replace(lower-case($title), '[- ]+', '_')"/><xsl:text>/</xsl:text><xsl:value-of select="replace(lower-case($author),'[ ]+','_')"/><xsl:value-of select="concat('/', $format)"/>
                       </xsl:otherwise>
                    </xsl:choose>
                </field>
                
                <field name="work_title3_key_ssort_stored">
                    <xsl:variable name="title">
                        <xsl:call-template name="cleantitle" >
                            <xsl:with-param name="title" select="arr[@name='title']/str[1]"/>
                            <xsl:with-param name="language" select="arr[@name='dc.language']/str"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:variable name="author">
                        <xsl:value-of select="arr[@name='author']/str[1]"/>
                    </xsl:variable>
                    <xsl:variable name="format">
                        <xsl:call-template name="getformat" />
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="contains($author, ', ')" >
                            <xsl:variable name="firstName">
                                <xsl:value-of select="substring-after($author, ', ')"/>
                            </xsl:variable>
                            <xsl:variable name="lastName">
                                <xsl:value-of select="substring-before($author, ', ')"/>
                            </xsl:variable>
                            <xsl:value-of select="replace(lower-case($title), '[- ]+', '_')"/><xsl:text>/</xsl:text><xsl:value-of select="replace(lower-case($lastName),'[ ]+','_')"/>
                            <xsl:text>_</xsl:text><xsl:value-of select="replace(lower-case($firstName),'[ ]+','_')"/><xsl:value-of select="concat('/', $format)"/>
                       </xsl:when>
                       <xsl:otherwise>
                            <xsl:value-of select="replace(lower-case($title), '[- ]+', '_')"/><xsl:text>/</xsl:text><xsl:value-of select="replace(lower-case($author),'[ ]+','_')"/><xsl:value-of select="concat('/', $format)"/>
                       </xsl:otherwise>
                    </xsl:choose>
                </field>
                
                <!--  stuff for authors -->
                <xsl:for-each select="distinct-values(arr[@name = 'author']/str)">
                    <xsl:sort select="translate(substring-before(substring-after(., 'index&quot;:'), ','), '\&quot;', '')" />
                    <xsl:variable name="isNoneProvided">
                        <xsl:call-template name="isNoneProvided">
                            <xsl:with-param name="value" select="." />
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:variable name="firstName">
                        <xsl:choose>
                            <xsl:when test="contains(., ',')">
                                <xsl:value-of select="substring-after(., ', ')" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="''" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    
                    <xsl:variable name="lastName">
                        <xsl:choose>
                            <xsl:when test="contains(., ',')">
                                <xsl:value-of select="substring-before(., ', ')" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="." />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$isNoneProvided != 'true'" >
                            <field name="author_tsearch_stored" >
                                <xsl:value-of select="$firstName" /><xsl:text> </xsl:text><xsl:value-of select="$lastName"/>
                            </field>
                            <field name="author_facet_f_stored" >
                                   <xsl:call-template name="lastcommafirst">
                                     <xsl:with-param name="first" select="$firstName"/>
                                     <xsl:with-param name="last" select="$lastName"/>
                                 </xsl:call-template>
                             </field> 
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
                
                <xsl:for-each select="distinct-values(arr[@name='author']/str[1])">
                    <field name="author_ssort_stored">
                        <xsl:value-of select="lower-case(substring-before(., ', '))"/>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="lower-case(substring-after(., ', '))"/>
                    </field>
                </xsl:for-each>

                <xsl:for-each select="arr[@name='dc.description']/str">
                    <field name="note_tsearch_stored"><xsl:value-of select="normalize-space(string(.))"/></field>
                </xsl:for-each>
                
                <xsl:choose>
                    <xsl:when test="arr[@name='dc.language']">
                        <xsl:for-each select="arr[@name='dc.language']/str">
                             <field name="language_f_stored"><xsl:value-of select="."/></field>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <field name="language_f_stored">English</field>
                    </xsl:otherwise>
                </xsl:choose>
                    <xsl:if test="arr[@name='dc.description.abstract']/str != '' and arr[@name='dc.description.abstract']/str != 'Enter your description here'">
                        <field name="abstract_tsearch_stored"><xsl:value-of select="arr[@name='dc.description.abstract']/str" /></field>
                </xsl:if>
                <field name="date_indexed_f_stored"><xsl:call-template name="formatDateTime">
                    <xsl:with-param name="dateTime"><xsl:value-of select='current-dateTime()'/></xsl:with-param>
                    </xsl:call-template>
                </field>
                <xsl:if test="arr[@name='subject']/str != ''">
                    <xsl:for-each select="arr[@name='subject']/str">
                        <field name="subject_tsearchf_stored"><xsl:value-of select="."/></field>
                    </xsl:for-each>
                </xsl:if>
                    
                <xsl:choose>
                    <xsl:when test="contains(arr[@name='dc.identifier.doi']/str, 'doi:')">
                        <field name="url_str_stored">
                            <xsl:value-of select="concat($urlbase, substring-after(arr[@name='dc.identifier.doi']/str, 'doi:'))"/>
                        </field>
                        <field name="url_label_str_stored">
                            <xsl:text>Access Online</xsl:text>
                        </field>
                    </xsl:when>
                    <xsl:otherwise>
                        <field name="url_str_stored">
                            <xsl:value-of select="concat($urlbase, arr[@name='dc.identifier.doi']/str)"/>
                        </field>
                        <field name="url_label_str_stored">
                            <xsl:text>Access Online</xsl:text>
                        </field>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:call-template name="extract-department">
                    <xsl:with-param name="publisher" select="arr[@name='dc.publisher']/str[1]/text()" />
                </xsl:call-template>
                <xsl:for-each select="distinct-values(arr[@name='dc.identifier.uri']/str)">
                    <xsl:if test="contains(., '.') and not(contains(., 'doi.org'))">
                        <field name="url_supp_str_stored">
                            <xsl:value-of select="."/>
                        </field>
                        <field name="url_label_supp_str_stored">
                            <xsl:value-of select="'Related Materials'"/>
                        </field>
                    </xsl:if>
                </xsl:for-each>
                    <xsl:for-each select="distinct-values(arr[@name='dc.description.sponsorship']/str)">
                    <field name="sponsoring_agency_tsearch_stored"><xsl:value-of select="."/></field>
                </xsl:for-each>
                <xsl:for-each select="distinct-values(arr[@name='dc.rights']/str)">
                    <field name="rights_tsearchf_stored"><xsl:value-of select="."/></field>
                </xsl:for-each>
                <xsl:if test="not(arr[@name='dc.rights.uri'])">
                    <xsl:choose>
                        <xsl:when test="contains(arr[@name='rights_display_ssm']/str, 'NoC-US')" >
                            <field name="rs_uri_a">http://rightsstatements.org/vocab/NoC-US/1.0/</field>
                        </xsl:when>
                        <xsl:otherwise>
                            <field name="rs_uri_a">http://rightsstatements.org/vocab/InC/1.0/</field>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                <xsl:for-each select="distinct-values(arr[@name='dc.rights.uri']/str)">
                    <xsl:variable name="uri" select="normalize-space(.)" />
                    <field name="rights_url_a"><xsl:value-of select="$uri"/>"</field>
                    <xsl:if test="starts-with($uri, 'http://creativecommons.org/publicdomain/zero/')">
                        <field name="cc_uri_a"><xsl:value-of select="$uri"/></field>
                        <field name="cc_type_tsearch_stored">creative commons public domain CC0</field>
                        <field name="license_class_f_stored">Public Domain</field>
                        <field name="use_f_stored">Educational Use Permitted</field>
                        <field name="use_f_stored">Commercial Use Permitted</field>
                        <field name="use_f_stored">Modifications Permitted</field> 
                    </xsl:if>
                    <xsl:if test="starts-with($uri, 'http://creativecommons.org/licenses/')">
                        <xsl:variable name="licenseProperties" select="substring-before(substring-after($uri, 'http://creativecommons.org/licenses/'), '/')"/>
                        <field name="cc_uri_a"><xsl:value-of select="$uri"/></field>
                        <field name="use_f_stored">Educational Use Permitted</field>
                        <field name="cc_type_tsearch_stored">creative commons CC</field>
                        <xsl:if test="contains($licenseProperties, 'by')">
                            <field name="cc_type_tsearch_stored">attribution BY</field>
                            <field name="license_class_f_stored">Attribution</field>
                        </xsl:if>
                        <xsl:if test="contains($licenseProperties, 'nc')">
                            <field name="cc_type_tsearch_stored">non-commercial NC</field>
                            <field name="license_class_f_stored">Non-Commercial</field>
                        </xsl:if>
                        <xsl:if test="not(contains($licenseProperties, 'nc'))">
                            <field name="use_f_stored">Commercial Use Permitted</field>
                        </xsl:if>
                        <xsl:if test="contains($licenseProperties, 'nd')">
                            <field name="cc_type_tsearch_stored">no derivatives ND</field>
                            <field name="license_class_f_stored">No Derivatives</field>
                        </xsl:if>
                        <xsl:if test="not(contains($licenseProperties, 'nd'))">
                            <field name="use_f_stored">Modifications Permitted</field>
                        </xsl:if>
                        <xsl:if test="contains($licenseProperties, 'sa')">
                            <field name="cc_type_tsearch_stored">share-alike SA</field>
                            <field name="license_class_f_stored">Share-Alike</field>
                        </xsl:if>
                    </xsl:if>
                </xsl:for-each>
                
                <field name="format_f_stored">
                    <xsl:call-template name="getformat" />
                </field>
                <field name="format_orig_tsearch_stored">
                    <xsl:value-of select="arr[@name='dc.type']/str"/>
                </field>
                
                <field name="format_f_stored">
                    <xsl:text>Online</xsl:text>
                </field>
                    <xsl:if test="arr[@name='dateIssued']/str/text() != ''">
                        <xsl:variable name="dateCreated" select="arr[@name='dateIssued']/str/text()" />
                    <field name="date_received_f_stored">
                        <xsl:call-template name="formatDate">
                            <xsl:with-param name="date" select="$dateCreated"/>
                        </xsl:call-template>
                    </field>
                </xsl:if> 
            </doc>
        </xsl:for-each>
        </add>
    </xsl:for-each>  
    </xsl:template>
    
    <xsl:template name="relatedNames">
        <xsl:param name="authors" />
        <xsl:param name="contributors" />
        <xsl:for-each select="tokenize($authors,'&quot;id&quot;')" >
            <xsl:sort select="translate(substring-before(substring-after(., 'index&quot;:'), ','), '\&quot;', '')" /><xsl:value-of select="'&quot;first_name'"/>
            <xsl:value-of select="substring-before(substring-after(., 'first_name'),',&quot;comput')"/>
            <xsl:value-of select="'###'"/>
        </xsl:for-each>
        <xsl:for-each select="tokenize($contributors,'&quot;id&quot;')">
            <xsl:sort select="translate(substring-before(substring-after(., 'index&quot;:'), ','), '\&quot;', '')" /><xsl:value-of select="'&quot;first_name'"/>
            <xsl:value-of select="substring-before(substring-after(., 'first_name'),',&quot;comput')"/>
            <xsl:value-of select="'###'"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="formatDateTime">
        <xsl:param name="dateTime" />
        <xsl:variable name="date" select="substring-before($dateTime, 'T')" />
        <xsl:variable name="year" select="substring-before($date, '-')" />
        <xsl:variable name="month" select="substring-before(substring-after($date, '-'), '-')" />
        <xsl:variable name="day" select="substring-after(substring-after($date, '-'), '-')" />
        <xsl:variable name="time" select="substring-after($dateTime, 'T')" />
        <xsl:variable name="hour" select="substring-before($time, ':')" />
        <xsl:variable name="minute" select="substring-before(substring-after($time, ':'), ':')" />
        <xsl:value-of select="concat($year, $month, $day, $hour, $minute)" />
    </xsl:template>
    
    <xsl:template name="formatDate">
        <xsl:param name="date" />
        <xsl:variable name="dateFixed" select="replace($date, '-' , '/')"/>
        <xsl:variable name="year" select="substring-before($dateFixed, '/')" />
        <xsl:variable name="month" select="substring-before(substring-after($dateFixed, '/'), '/')" />
        <xsl:variable name="day" select="substring-after(substring-after($dateFixed, '/'), '/')" />
        <xsl:value-of select="substring(concat($year, $month, $day), 1, 8)" />
    </xsl:template>
    
    <xsl:template name="getformat">
        <xsl:choose>
            <xsl:when test="arr[@name='dc.type']/str = 'Article'" >
                <xsl:text>Article</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Audio'" >
                <xsl:text>Streaming Audio</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Book'" >
                <xsl:text>Book</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Book chapter'" >
                <xsl:text>Book</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Conference Proceeding'" >
                <xsl:text>Conference Paper</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Image'" >
                <xsl:text>Visual Materials</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Map'" >
                <xsl:text>Map</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Part of Book'" >
                <xsl:text>Book Chapter</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Poster'" >
                <xsl:text>Visual Materials</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Presentation'" >
                <xsl:text>Visual Materials</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Project'" >
                <xsl:text>Working Paper</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Technical Report'" >
                <xsl:text>Technical report</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Research Paper'" >
                <xsl:text>Working Paper</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Video'" >
                <xsl:text>Streaming Video</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Other'" >
                <xsl:text>Other Media</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Educational Resource'" >
                <xsl:text>Other Media</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Education'" >
                <xsl:text>Other Media</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Learning Object'" >
                <xsl:text>Other Media</xsl:text>
            </xsl:when>
            <xsl:when test="arr[@name='dc.type']/str = 'Funder'" >
                <xsl:text>Other Media</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>Other Media</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="isNoneProvided">
        <xsl:param name="value" />  
        <xsl:choose>
            <xsl:when test="$value = 'None Provided'">
                <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>false</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getFirstName">
        <xsl:param name="node"/>
        <xsl:variable name="othername" select="concat(substring-before($node/@name, '_last_name_t'), '_first_name_t')"/>
        <xsl:variable name="othernode" select="$node/../arr[@name = $othername]" />
        <xsl:value-of select="$othernode/str[1]"/>
    </xsl:template>
    
    <xsl:template name="lastcommafirst">
        <xsl:param name="last"/>
        <xsl:param name="first"/>
        <xsl:choose>
            <xsl:when test="string-length($last)= 0"><xsl:value-of select="$first"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="concat($last,', ',$first)"/></xsl:otherwise>
        </xsl:choose>    
    </xsl:template>
        
    <xsl:template name="cleantitle">
        <xsl:param name="title"/>
        <xsl:param name="language" select="''"/>
        <xsl:variable name="title1" select="lower-case($title)" />
        <xsl:variable name="title2" select='replace($title1, "( )?([^-a-z0-9&apos; ])( )?", "$1$3")' />
        
        <xsl:variable name="replacestr" >
            <xsl:choose>
                <xsl:when test="$language = 'English'">
                    <xsl-text>^[ ]*(the|a|an) </xsl-text>
                </xsl:when>
                <xsl:when test="$language = 'French'">
                    <xsl-text>^[ ]*(la |le |l&apos;|les |une |un |des )</xsl-text>
                </xsl:when>
                <xsl:when test="$language = 'Italian'">
                    <xsl-text>^[ ]*(uno |una |un |un&apos;|lo |gli |il |i |l&apos;|la |le )</xsl-text>
                </xsl:when>
                <xsl:when test="$language = 'Spanish'">
                    <xsl-text>^[ ]*(el|los|las|un|una|unos|unas) </xsl-text>
                </xsl:when>
                <xsl:when test="$language = 'German'">
                    <xsl-text>^[ ]*(der|die|das|den|dem|des|ein|eine[mnr]?|keine|[k]?einer) </xsl-text>
                </xsl:when>
                <xsl:when test="$language = '' or not(boolean($language))">
                    <xsl-text>^[ ]*(the|a|an) </xsl-text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl-text>^##PlaceholderMatchingNothing$</xsl-text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="title3" select="replace($title2, $replacestr,'')" />
        <xsl:variable name="title4" select="replace($title3,'^[ ]+|[ ]+$','')" />
        <xsl:variable name="title5" select='replace($title4,"&apos;","")' />
        <xsl:value-of select="replace($title5,'[ ][ ]+',' ')" />  
    </xsl:template>
    
    <xsl:template name="publisherinfo">
        <xsl:variable name="dateValue" select="arr[@name='dateIssued']/str"/>
        <xsl:variable name="datestring" >
            <xsl:choose>
                <xsl:when test="matches($dateValue, '^\d{4}-01-01.*$')">
                    <xsl:value-of select="substring($dateValue, 1, 4)"/>
                </xsl:when>
                <xsl:when test="matches($dateValue, '^\d{4}-d{2}-\d{2}.*$')">
                    <xsl:value-of select="substring($dateValue, 1, 10)"/>
                </xsl:when>
                <xsl:when test="matches($dateValue, '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:.*$')">
                    <xsl:value-of select="substring($dateValue, 1, 10)"/>
                </xsl:when>
                <xsl:when test="$dateValue != ''">
                    <xsl:value-of select="$dateValue"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="arr[@name='dc.publisher']/str != ''">
                <xsl:value-of select="concat(arr[@name='dc.publisher']/str, ', ', $datestring)" />
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="extract-department">
        <xsl:param name="publisher"/>
      
        <!-- Clean trailing degree or date info -->
        <xsl:variable name="cleaned" select="replace($publisher, ',\s*(BA|BS|MA|MS|PhD).*$', '')"/>
      
        <xsl:choose>
            <!-- Case: Exactly 'University of Virginia Library' -->
            <xsl:when test="$cleaned = 'University of Virginia Library'">
                <field name="department_tsearch_stored">
                  <xsl:value-of select="$cleaned"/>
                </field>
            </xsl:when>
        
            <!-- Case: Contains 'University of Virginia' -->
            <xsl:when test="contains($cleaned, 'University of Virginia')">
                <xsl:variable name="before">
                    <!-- Strip 'University of Virginia' and punctuation before/after -->
                    <xsl:choose>
                        <!-- UVA is at the end -->
                        <xsl:when test="ends-with($cleaned, 'University of Virginia')">
                            <xsl:value-of select="normalize-space(replace($cleaned, ',?\s*University of Virginia$', ''))"/>
                        </xsl:when>
                        <!-- UVA is at the beginning -->
                        <xsl:when test="starts-with($cleaned, 'University of Virginia')">
                            <xsl:value-of select="normalize-space(replace($cleaned, '^University of Virginia,?\s*', ''))"/>
                        </xsl:when>
                        <!-- UVA in the middle -->
                        <xsl:otherwise>
                            <xsl:value-of select="normalize-space(replace($cleaned, ',?\s*University of Virginia,?\s*', ''))"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
          
                <!-- Only emit if there's something meaningful -->
                <xsl:if test="$before != ''">
                    <field name="department_tsearch_stored">
                        <xsl:value-of select="replace(normalize-space($before), '^(or\s+|/+ ?)', '')"/>
                    </field>
                </xsl:if>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="publisheddate">
        <xsl:variable name="datestring" >
            <xsl:choose>
                <xsl:when test="matches(arr[@name='dateIssued']/str, '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:.*$')">
                    <xsl:value-of select="substring(arr[@name='dateIssued']/str, 1, 10)"/>
                </xsl:when>
                <xsl:when test="arr[@name='dateIssued']/str != ''">
                    <xsl:value-of select="arr[@name='dateIssued']/str"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring(replace(arr[@name='dateIssued']/str, '/', '-'), 1, 10)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$datestring" />
    </xsl:template>
    
    <xsl:template name="publisheddatetime">
        <xsl:variable name="datetimestring" >
            <xsl:choose>
                <xsl:when test="matches(arr[@name='dateIssued']/str, '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:.*$')">
                    <xsl:value-of select="concat(substring(arr[@name='dateIssued']/str, 1, 17), '00Z')"/>
                </xsl:when>
                <xsl:when test="matches(arr[@name='dateIssued']/str, '\d{4}[-/]\d{2}[-/]-\d{2}')">
                    <xsl:value-of select="concat(replace(substring(arr[@name='dateIssued']/str, 1, 10), '/', '-'), 'T00:00:00Z')"/>
                </xsl:when>
                <xsl:when test="matches(arr[@name='dateIssued']/str, '\d{4}')">
                    <xsl:value-of select="concat(arr[@name='dateIssued']/str, '-01-01T00:00:00Z')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat(substring(replace(arr[@name='dateIssued']/str, '/', '-'), 1, 10),  'T00:00:00Z')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$datetimestring" />
    </xsl:template>
    
    <xsl:template name="publisheddateYYYY">
        <xsl:variable name="datestring" >
            <xsl:choose>
                <xsl:when test="matches(arr[@name='dateIssued']/str, '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:.*$')">
                    <xsl:value-of select="substring(arr[@name='dateIssued']/str, 1, 4)"/>
                </xsl:when>
                <xsl:when test="matches(arr[@name='dateIssued']/str, '.*\d{4}.*')">
                    <xsl:analyze-string select="arr[@name='dateIssued']/str" regex=".*(\d\d\d\d).*">
                        <xsl:matching-substring>
                            <xsl:value-of select="regex-group(1)"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring(arr[@name='dateIssued']/str , 1, 4)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$datestring"/>
    </xsl:template>

    <!-- handles fixing all of the dates. Can create a date or a daterange -->
    <xsl:template name="fixDate">
        <xsl:param name="field"/>
        <xsl:param name="datestring"/>
        <xsl:param name="monthDefault" />
        <xsl:param name="dayDefault" />
        <xsl:param name="timeDefault"/>
        <xsl:param name="range"/>
        <xsl:variable name="fmtdate">
            <xsl:choose>
                <xsl:when test="matches($datestring, '([0-9][0-9][0-9][0-9])[~?]?[/]([0-9][0-9][0-9][0-9])[~?]?(.*)')">
                    <xsl:analyze-string select="$datestring" regex="([0-9][0-9][0-9][0-9])[~?]?[/]([0-9][0-9][0-9][0-9])[~?]?(.*)">
                        <xsl:matching-substring>
                            <xsl:variable name="year1" select="number(regex-group(1))"/>
                            <xsl:variable name="year2" select="number(regex-group(2))"/>
                            <xsl:choose>
                                <xsl:when test="$range = 'true'">
                                    <xsl:value-of select="concat('[',$year1, ' TO ', $year2, ']')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="concat($year1,  $monthDefault, $dayDefault, $timeDefault)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>
                <xsl:when test="matches($datestring, '([0-9][0-9][0-9][0-9])[-/]([0-9][0-9]?)[-/]([0-9][0-9]?)(.*)')">
                    <xsl:analyze-string select="$datestring" regex="([0-9][0-9][0-9][0-9])[-/]([0-9][0-9]?)[-/]([0-9][0-9]?)(.*)">
                        <xsl:matching-substring>
                            <xsl:variable name="month" select="number(regex-group(2))"/>
                            <xsl:variable name="day" select="number(regex-group(3))"/>
                            <xsl:variable name="year" select="number(regex-group(1))"/>
                            <xsl:choose>
                                <!-- Omit month/day if they are both 1 and dayDefault is not set -->
                                <xsl:when test="$month = 1 and $day = 1 and not(string($dayDefault))">
                                    <xsl:value-of select="string($year)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="concat($year, '-', format-number($month, '00'), '-', format-number($day, '00'), $timeDefault)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>

               <!--
                <xsl:when test="matches($datestring, '([0-9][0-9][0-9][0-9])[-/]([0-9][0-9]?)[-/]([0-9][0-9]?)(.*)')">
                    <xsl:analyze-string select="$datestring" regex="([0-9][0-9][0-9][0-9])[-/]([0-9][0-9]?)[-/]([0-9][0-9]?)(.*)">
                        <xsl:matching-substring>
                            <xsl:variable name="month" select="number(regex-group(2))"/>
                            <xsl:variable name="day" select="number(regex-group(3))"/>
                            <xsl:variable name="year" select="number(regex-group(1))"/>
                            <xsl:value-of select="concat($year, '-', format-number($month, '00'), '-', format-number($day, '00'), $timeDefault)" />
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>
                -->
                <xsl:when test="matches($datestring, '[^0-9]*([0-9][0-9][0-9][0-9])(.*)')">
                    <xsl:analyze-string select="$datestring" regex="[^0-9]*([0-9][0-9][0-9][0-9])(.*)">
                        <xsl:matching-substring>
                            <xsl:variable name="year" select="number(regex-group(1))"/>
                            <xsl:value-of select="concat($year, $monthDefault, $dayDefault, $timeDefault)" />
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>
                <xsl:when test="matches($datestring, '[^0-9]*([0-9][0-9][0-9])X(.*)')">
                    <xsl:analyze-string select="$datestring" regex="[^0-9]*([0-9][0-9][0-9])X(.*)">
                        <xsl:matching-substring>
                            <xsl:variable name="yearstart" select="number(regex-group(1))"/>
                            <xsl:variable name="yearunits" select="number(regex-group(1))"/>
                            <xsl:choose>
                                <xsl:when test="$range = 'true'">
                                    <xsl:value-of select="concat('[',$yearstart, '0', ' TO ', $yearstart, '9', ']')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="concat($yearstart,'5', $monthDefault, $dayDefault, $timeDefault)"/>

                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>
                <xsl:otherwise>
                    <!--   <xsl:value-of select="concat('%%%%%', $datestring, '%%%%%')"/> -->
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="$fmtdate != ''">
            <xsl:element name="field">
                <xsl:attribute name="name"><xsl:value-of select="$field"/></xsl:attribute>
                <xsl:value-of select="$fmtdate" />
            </xsl:element>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
