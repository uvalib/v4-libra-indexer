<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
    <xsl:output indent="yes" />
    <xsl:variable name="urlbase" select="string('https://doi.org/')" />

    <xsl:template match='/'>

        <xsl:for-each select="/response/result">
            <add>
        <!--                <xsl:for-each select="doc"> -->
            <xsl:for-each select="doc[arr[@name='has_model_ssim']/str = 'GenericWork']">
            <doc>
                <xsl:variable name="isThesis">
                    <xsl:call-template name="isThesis">
                        <xsl:with-param name="worktype" select="arr[@name='work_type_tesim']/str" />
                    </xsl:call-template>
                </xsl:variable>
                <field name="id"><xsl:value-of select="str[@name='id']" /></field>
   <!--              <field name="source_facet">Libra2 Repository</field> -->
                <field name="source_f_stored">Libra Repository</field>
                <field name="digital_collection_f_stored">Libra ETD Repository</field>
                <field name="data_source_f_stored">libraetd</field>
                <field name="pool_f_stored">thesis</field>
                <!--             <field name="digital_collection_f_stored">Libra Repository</field>  -->
                <field name="doc_type_f_stored">libra</field>
                <field name="location_f_stored">Internet Materials</field>
                <field name="shadowed_location_f_stored">
                    <xsl:choose>
                        <xsl:when test="arr[@name='draft_tesim']/str = 'false'">
                            <xsl:text>VISIBLE</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>HIDDEN</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </field>
                <field name="uva_availability_f_stored">Online</field>
                <field name="anon_availability_f_stored">
                    <xsl:choose>
                        <xsl:when test="arr[@name='embargo_state_tesim']/str = 'open'">
                            <xsl:text>Online</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>Request</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                </field>
                <!--               <xsl:if test="arr[@name='date_published_tesim']/str != ''">
                    <xsl:variable name="yearPub" >                     
                        <xsl:value-of select="replace(arr[@name='date_published_tesim']/str, '.*(\d\d\d\d).*$', '$1')" />
                    </xsl:variable>
                    <xsl:call-template name="year_multisort_publisheddatefacet">
                        <xsl:with-param name="yearPub" select="$yearPub" />
                    </xsl:call-template>
                   < ! - - <field name="year_multisort_i"><xsl:value-of select="substring(arr[@name='date_published_tesim']/str, 1, 4)" /></field> - ->
                </xsl:if> -->
                <xsl:if test="arr[@name='date_published_tesim']/str != ''">
                    <xsl:call-template name="fixDate">
                        <xsl:with-param name="field">published_daterange</xsl:with-param>
                        <xsl:with-param name="datestring"><xsl:value-of select="arr[@name='date_published_tesim']/str" /></xsl:with-param>
                        <xsl:with-param name="range">true</xsl:with-param>
                    </xsl:call-template>
                    <xsl:call-template name="fixDate">
                        <xsl:with-param name="field">published_display_a</xsl:with-param>
                        <xsl:with-param name="datestring"><xsl:value-of select="arr[@name='date_published_tesim']/str" /></xsl:with-param>
                        <xsl:with-param name="range">true</xsl:with-param>
                    </xsl:call-template>
                    <xsl:call-template name="fixDate">
                        <xsl:with-param name="field">published_date</xsl:with-param>
                        <xsl:with-param name="datestring"><xsl:value-of select="arr[@name='date_published_tesim']/str" /></xsl:with-param>
                        <xsl:with-param name="monthDefault">-01</xsl:with-param>
                        <xsl:with-param name="dayDefault">-01</xsl:with-param>
                        <xsl:with-param name="timeDefault">T00:00:00Z</xsl:with-param>
                    </xsl:call-template>       
                </xsl:if>
                <xsl:for-each select="arr[@name = 'degree_tesim']/str">
                    <field name="degree_tsearch_stored"><xsl:value-of select="."/></field>
                </xsl:for-each>
                <xsl:for-each select="arr[@name = 'department_tesim']/str">
                    <field name="department_tsearchf_stored"><xsl:value-of select="."/></field>
                </xsl:for-each>
                <field name="published_tsearch_stored">
                    <xsl:call-template name="publisherinfo"/>
                </field>
                <field name="title_tsearch_stored"><xsl:value-of select="arr[@name='title_tesim']/str[1]" /></field>
                <field name="title_sort_stored"><xsl:call-template name="cleantitle" >
                    <xsl:with-param name="title" select="arr[@name='title_tesim']/str[1]"/>
                    <xsl:with-param name="language" select="arr[@name='language_tesim']/str"/>
                    </xsl:call-template></field>
                <xsl:for-each select="arr[@name='mods_journal_title_info_t']">
                    <field name="journal_title_tsearch_stored">
                        <xsl:value-of select="str" />
                    </field>
                </xsl:for-each> 
                <!--  stuff for authors -->
                <xsl:for-each select="arr[@name = 'author_last_name_tesim']">
                    <xsl:variable name="isNoneProvided">
                        <xsl:call-template name="isNoneProvided">
                            <xsl:with-param name="node" select="." />
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:variable name="firstName">
                        <xsl:value-of select="../arr[@name='author_first_name_tesim']/str" />
                    </xsl:variable>
                   <xsl:choose>
                        <xsl:when test="$isNoneProvided != 'true'" >
                            <field name="author_tsearch_stored">
                                <xsl:call-template name="lastcommafirst">
                                    <xsl:with-param name="first" select="$firstName"/>
                                    <xsl:with-param name="last" select="str[1]"/>
                                </xsl:call-template>
                            </field>
                            <field name="author_facet_f_stored">
                                <xsl:call-template name="lastcommafirst">
                                    <xsl:with-param name="first" select="$firstName"/>
                                    <xsl:with-param name="last" select="str[1]"/>
                                </xsl:call-template>
                            </field>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>

                <!--  stuff for contributors -->
                <xsl:for-each select="arr[@name = 'contributor_tesim']/str">
                     <xsl:sort select="number(substring-before(., '&#10;'))" order="ascending"/>
                     <xsl:variable name="isNoneProvided">
                        <xsl:call-template name="isNoneProvided">
                            <xsl:with-param name="node" select="." />
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:variable name="firstName">
                        <xsl:value-of select="substring-before(substring-after(substring-after(text(), '&#10;'), '&#10;'), '&#10;')" />
                    </xsl:variable>
                    <xsl:variable name="lastName">
                        <xsl:value-of select="substring-before(substring-after(substring-after(substring-after(text(), '&#10;'), '&#10;'), '&#10;'), '&#10;')" />
                    </xsl:variable>
                    <xsl:variable name="institutionName">
                        <xsl:value-of select="substring-after(substring-after(substring-after(substring-after(substring-after(text(), '&#10;'), '&#10;'), '&#10;'), '&#10;'), '&#10;')" />
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$isThesis = 'true' and  $isNoneProvided != 'true' and $firstName != '' and $lastName != ''" >
                            <field name="author_added_entry_tsearch_stored" >
                                <xsl:call-template name="lastcommafirst">
                                    <xsl:with-param name="first" select="$firstName"/>
                                    <xsl:with-param name="last" select="$lastName"/>
                                </xsl:call-template>
                            </field>
                            <field name="author_facet_f_stored">
                                <xsl:call-template name="lastcommafirst">
                                    <xsl:with-param name="first" select="$firstName"/>
                                    <xsl:with-param name="last" select="$lastName"/>
                                </xsl:call-template>
                                <xsl:text> (advisor)</xsl:text>                            </field>
                        </xsl:when>
                        <xsl:when test="$isThesis != 'true' and  $isNoneProvided != 'true'" >
                            <field name="author_tsearch">
                                <xsl:call-template name="lastcommafirst">
                                    <xsl:with-param name="first" select="$firstName"/>
                                    <xsl:with-param name="last" select="$lastName"/>
                                </xsl:call-template>
                            </field>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>

                <field name="author_sort_stored">
                    <xsl:value-of select="lower-case(arr[@name='author_last_name_tesim']/str[1])"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="lower-case(arr[@name='author_first_name_tesim']/str[1])"/>
                </field>
                <field name="work_title2_key_ssort_stored">
                    <xsl:variable name="title">
                        <xsl:call-template name="cleantitle" >
                            <xsl:with-param name="title" select="arr[@name='title_tesim']/str[1]"/>
                            <xsl:with-param name="language" select="arr[@name='language_tesim']/str"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:value-of select="replace(lower-case($title), '[- ]+', '_')"/><xsl:text>/</xsl:text><xsl:value-of select="replace(lower-case(arr[@name='author_last_name_tesim']/str[1]),'[ ]+','_')"/>
                    <xsl:text>_</xsl:text><xsl:value-of select="replace(lower-case(arr[@name='author_first_name_tesim']/str[1]),'[ ]+','_')"/><xsl:text>/Thesis</xsl:text>
                </field>
                
                
                <xsl:for-each select="arr[@name='language_tesim']/str">
                    <field name="language_f_stored"><xsl:value-of select="."/>
                    </field>
                </xsl:for-each>
                <xsl:if test="arr[@name='description_tesim']/str != '' and arr[@name='description_tesim']/str != 'Enter your description here'">
                    <xsl:variable name="summary"><xsl:value-of select="replace(arr[@name='description_tesim']/str, '[ ]*&#10;+[ ]*', ' \\n ')"/></xsl:variable>
                    <field name="subject_summary_tsearch_stored"><xsl:value-of select="$summary" /></field>
                    <field name="abstract_tsearch_stored"><xsl:value-of select="$summary" /></field>
                </xsl:if>
                <xsl:if test="arr[@name='notes_tesim']/str != '' and arr[@name='notes_tesim']/str != 'Enter your description here'">
                    <xsl:variable name="notes"><xsl:value-of select="replace(arr[@name='notes_tesim']/str, '[ ]*&#10;+[ ]*', ' \\n ')"/></xsl:variable>
                    <field name="note_tsearch_stored"><xsl:value-of select="$notes" /></field>
                 </xsl:if>
                <field name="date_indexed_f_stored"><xsl:call-template name="formatDateTime">
                    <xsl:with-param name="dateTime"><xsl:value-of select='current-dateTime()'/></xsl:with-param>
                    </xsl:call-template>
                </field>
                <xsl:if test="arr[@name='keyword_tesim']/str != ''">
                    <xsl:for-each select="arr[@name='keyword_tesim']/str">
                        <field name="subject_tsearchf_stored"><xsl:value-of select="."/></field>
                    </xsl:for-each>
                </xsl:if>

<!--                <xsl:if test="arr[@name='subject_topic_t']/str != ''">
                    <xsl:for-each select="arr[@name='subject_topic_t']/str">
                        <field name="subject_facet"><xsl:value-of select="."/></field>
                    </xsl:for-each>
                    <xsl:for-each select="arr[@name='subject_topic_t']/str">
                        <field name="subject_text"><xsl:value-of select="."/></field>
                    </xsl:for-each>
                </xsl:if>
-->
                <xsl:choose>
                    <xsl:when test="contains(arr[@name='identifier_tesim']/str, 'doi:')">
                        <field name="url_str_stored">
                            <xsl:value-of select="concat($urlbase, substring-after(arr[@name='identifier_tesim']/str, 'doi:'))"/>
                        </field>
                        <field name="url_label_str_stored">
                            <xsl:value-of select="'Access Online'"/>
                        </field>
                    </xsl:when>
                    <xsl:otherwise>
                        <field name="url_str_stored">
                            <xsl:value-of select="concat($urlbase, arr[@name='identifier_tesim']/str)"/>
                        </field>
                        <field name="url_label_str_stored">
                            <xsl:value-of select="'Access Online'"/>
                        </field>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:for-each select="distinct-values(arr[@name='related_url_tesim']/str)">
                    <xsl:if test="contains(. , '.')" >
                        <field name="url_supp_str_stored">
                            <xsl:value-of select="."/>
                        </field>
                        <field name="url_label_supp_str_stored">
                            <xsl:value-of select="'Related Materials'"/>
                        </field>
                    </xsl:if>
                </xsl:for-each>
                <xsl:if test="arr[@name='thumbnail_url_display_ssm']/str != ''">
                    <field name="thumbnail_url_str_stored"><xsl:value-of select="arr[@name='thumbnail_url_display_ssm']/str"/></field>
                </xsl:if>
                <xsl:for-each select="distinct-values(arr[@name='sponsoring_agency_tesim']/str)">
                    <field name="sponsoring_agency_tsearch_stored"><xsl:value-of select="."/></field>
                </xsl:for-each>
                <xsl:for-each select="distinct-values(arr[@name='rights_display_ssm']/str)">
                    <field name="rights_tsearchf_stored"><xsl:value-of select="."/></field>
                </xsl:for-each>
                <xsl:for-each select="distinct-values(arr[@name='rights_url_ssm']/str)">
                    <field name="rights_url_a"><xsl:value-of select="."/></field>
                </xsl:for-each>
 <!--                <xsl:call-template name="dataverse">
                    <xsl:with-param name="libra-id"><xsl:value-of select="string(./str[@name='id'])"/></xsl:with-param>
                </xsl:call-template>
-->
 <!--               <xsl:variable name="pid" select="concat('info:fedora/', string(./str[@name='id']))"/>
                <xsl:for-each select="/response/result/doc[arr[@name='has_model_s']/str='info:fedora/afmodel:FileAsset' and arr[@name='is_part_of_s']/str = $pid]/str[@name='id']">
                    <field name="url_display">
                          <xsl:value-of select="concat($urlbase, 'file_assets/', string(.), '||Full Text Document')"/>
                    </field>
                </xsl:for-each> -->
                <xsl:if test="not(arr[@name='rights_url_ssm'])">
                    <xsl:choose>
                        <xsl:when test="contains(arr[@name='rights_display_ssm']/str, 'NoC-US')" >
                            <field name="rs_uri_a">http://rightsstatements.org/vocab/NoC-US/1.0/</field>
                        </xsl:when>
                        <xsl:otherwise>
                            <field name="rs_uri_a">http://rightsstatements.org/vocab/InC/1.0/</field>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                <xsl:for-each select="distinct-values(arr[@name='rights_url_ssm']/str)">
                    <xsl:variable name="cc_license_path" select="substring-after(., 'creativecommons.org/')" />
                    <xsl:variable name="uri" select="concat('http://creativecommons.org/', $cc_license_path)" />
                    <xsl:if test="starts-with($uri, 'http://creativecommons.org/publicdomain/zero/')">
                        <field name="cc_uri_a"><xsl:value-of select="$uri"/></field>
                        <field name="cc_type_tsearch">creative commons public domain CC0</field>
                        <field name="license_class_f_stored">Public Domain</field>
                        <field name="use_f_stored">Educational Use Permitted</field>
                        <field name="use_f_stored">Commercial Use Permitted</field>
                        <field name="use_f_stored">Modifications Permitted</field> 
                    </xsl:if>
                    <xsl:if test="starts-with($uri, 'http://creativecommons.org/licenses/')">
                        <xsl:variable name="licenseProperties" select="substring-before(substring-after($uri, 'http://creativecommons.org/licenses/'), '/')"/>
                        <field name="cc_uri_a"><xsl:value-of select="$uri"/></field>
                        <field name="use_f_stored">Educational Use Permitted</field>
                        <field name="cc_type_tsearch">creative commons CC</field>
                        <xsl:if test="contains($licenseProperties, 'by')">
                            <field name="cc_type_tsearch">attribution BY</field>
                            <field name="license_class_f_stored">Attribution</field>
                        </xsl:if>
                        <xsl:if test="contains($licenseProperties, 'nc')">
                            <field name="cc_type_tsearch">non-commercial NC</field>
                            <field name="license_class_f_stored">Non-Commercial</field>
                        </xsl:if>
                        <xsl:if test="not(contains($licenseProperties, 'nc'))">
                            <field name="use_f_stored">Commercial Use Permitted</field>
                        </xsl:if>
                        <xsl:if test="contains($licenseProperties, 'nd')">
                            <field name="cc_type_tsearch">no derivatives ND</field>
                            <field name="license_class_f_stored">No Derivatives</field>
                        </xsl:if>
                        <xsl:if test="not(contains($licenseProperties, 'nd'))">
                            <field name="use_f_stored">Modifications Permitted</field>
                        </xsl:if>
                        <xsl:if test="contains($licenseProperties, 'sa')">
                            <field name="cc_type_tsearch">share-alike SA</field>
                            <field name="license_class_f_stored">Share-Alike</field>
                        </xsl:if>
                    </xsl:if>
                </xsl:for-each>

                <field name="format_f_stored">
                    <xsl:choose>
                        <xsl:when test="arr[@name='work_type_tesim']/str = 'thesis'" >
                            <xsl:text>Thesis/Dissertation</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </field>
                <field name="format_f_stored">
                    <xsl:text>Online</xsl:text>
                </field>
                <xsl:if test="arr[@name='date_created_tesim']/str/text() != ''">
                    <xsl:variable name="dateCreated" select="arr[@name='date_created_tesim']/str/text()" />
                    <field name="date_received_f_stored">
                        <xsl:call-template name="formatDate">
                            <xsl:with-param name="date" select="$dateCreated"/>
                        </xsl:call-template>
                    </field>
                </xsl:if> 
            </doc>
            <xsl:text>&#10;</xsl:text>
        </xsl:for-each>
      </add>
    </xsl:for-each>  
    </xsl:template>
    
    
    <xsl:template name="makeDate">
        <xsl:param name="field"/>
        <xsl:param name="datestring"/>
        <xsl:param name="pattern"/>
        <xsl:variable name="fmtdate">
            <xsl:analyze-string select="$datestring" regex="([0-9]+)[-/]([0-9]+)[-/]([0-9][0-9]?)(.*)">
              <xsl:matching-substring>
                  <xsl:variable name="month" select="number(regex-group(2))"/>
                  <xsl:variable name="day" select="number(regex-group(3))"/>
                  <xsl:variable name="year" select="number(regex-group(1))"/>
                  <xsl:variable name="dateTime" select="concat($year, '-', format-number($month, '00'), '-', format-number($day, '00'), $pattern)" />
                  <xsl:value-of select="$dateTime"/>
              </xsl:matching-substring>
              <xsl:non-matching-substring>
                  <xsl:analyze-string select="$datestring" regex="([0-9][0-9][0-9][0-9])(.*)">
                      <xsl:matching-substring>
                          <xsl:variable name="year" select="number(regex-group(1))"/>
                          <xsl:variable name="dateTime" select="concat($year, '-01-01', $pattern)" />
                          <xsl:value-of select="$dateTime"/>
                      </xsl:matching-substring>
                  </xsl:analyze-string>              
              </xsl:non-matching-substring>
           </xsl:analyze-string>
        </xsl:variable>
        <xsl:element name="field">
            <xsl:attribute name="name"><xsl:value-of select="$field"/></xsl:attribute>
            <xsl:value-of select="$fmtdate" />
        </xsl:element>
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
        <xsl:value-of select="concat($year, $month, $day)" />
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
                            <xsl:value-of select="concat($year, '-', format-number($month, '00'), '-', format-number($day, '00'), $timeDefault)" />
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>
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
    
    <xsl:template name="isThesis">
        <xsl:param name="worktype" />  
        <xsl:choose>
            <xsl:when test="$worktype = 'thesis'">
                <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>false</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="isNoneProvided">
        <xsl:param name="node" />  
        <xsl:choose>
            <xsl:when test="$node/str[1] = 'None Provided'">
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

<!--    <xsl:template name="dataverse" >
        <xsl:param name="libra-id"/>
        <xsl:variable name="dataverse-id" select="$dataverse-map/entry[libra = $libra-id]/dataverse"/>
        <xsl:if test="string-length(string($dataverse-id)) > 0">
            <field name="url_display">
                <xsl:value-of select="concat($dataverse-url, $dataverse-id, '||UVa Libra Data')"/>
            </field>
        </xsl:if>
    </xsl:template> -->
    
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
        <xsl:choose>
             <xsl:when test="arr[@name='work_type_tesim']/str = 'thesis'">
                <xsl:value-of select="concat(arr[@name='author_institution_tesim']/str, ', ', arr[@name='department_tesim']/str, ', ', arr[@name='degree_tesim']/str, ', ', substring(arr[@name='date_published_tesim']/str, 1, 4))" />
            </xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
