<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" 
    xmlns:l="http://language.data"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:rm="http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1" exclude-result-prefixes="l mods rm">
    <xsl:output indent="yes" />
    <xsl:variable name="urlbase" select="string('https://avalon-dev.lib.virginia.edu/media_objects/')" />
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz    '"/>
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ,;-:.'"/>
    <xsl:variable name="lang_lookup">
        <lang>
            <abb>eng</abb>
            <name>English</name>
        </lang>
    </xsl:variable>
    
    <xsl:template match="text()" priority="-1"/>
    
    <xsl:template match="add">
        <add>
            <xsl:apply-templates select="*"/>
        </add>
    </xsl:template>
    
    <xsl:template match="doc">
        <xsl:if test="arr[@name='has_model_ssim']/str = 'MediaObject'">
            <doc>
              <xsl:variable name="audio" select="arr[@name = 'avalon_resource_type_ssim']/str[text() = 'Sound Recording']"/>
              <xsl:variable name="video" select="arr[@name = 'avalon_resource_type_ssim']/str[text() = 'Moving Image']"/>
              <xsl:variable name="avalonId" select="str[@name = 'id']/text()" />
              <xsl:variable name="solrId" select="concat('avalon_', $avalonId)" />
                 
              <field name="id"><xsl:value-of select="$solrId" /></field>
              <field name="url_str_stored">
                  <xsl:value-of select="concat($urlbase, $avalonId)"/>
              </field>                  
              <!--             <field name="digital_collection_f_stored">Libra Repository</field>  -->
              
              <!-- Load MODS data from file based on filename built from id.  Invoke data extraction from MODS document -->
              <xsl:variable name="mods_doc" select="document(concat('./data/mods/', $avalonId, '_mods.xml'))"/>
  
              <xsl:apply-templates select="$mods_doc/node()"/>
              
              <field name="circulating_f">true</field>
              <field name="source_f_stored">Avalon</field>
              <field name="source_f_stored">UVA Library Digital Repository</field>
              <field name="record_date_stored">
                  <xsl:value-of select="current-dateTime()"/>
              </field>
              <field name="data_source_str_stored">avalon</field>
              <xsl:variable name="lang_name">
                  <xsl:choose>
                      <xsl:when test="mods:language/mods:languageTerm[@type='text']/text() != ''">
                          <xsl:value-of select="mods:language/mods:languageTerm[@type='text']/text()" />
                      </xsl:when>
                      <xsl:otherwise>
                          <xsl:value-of select="'English'" />
                      </xsl:otherwise>
                  </xsl:choose>
              </xsl:variable>
              <xsl:variable name="cleaned_title" >
                    <xsl:call-template name="cleantitle">
                        <xsl:with-param name="title" select="normalize-space(str[@name = 'title_tesi']/text())"/>
                        <xsl:with-param name="language" select="$lang_name"/>
                    </xsl:call-template>
                </xsl:variable>
                
              <xsl:if test="$audio and not($video)">
                  <field name="url_label_str_stored">Listen Online</field>
                  <field name="pool_f">music_recordings</field>
                  <field name="work_title3_key_ssort"><xsl:value-of select="translate(lower-case(concat($cleaned_title, '//MusicRecording')), ' ', '_')" /></field>
                  <field name="work_title2_key_ssort"><xsl:value-of select="translate(lower-case(concat($cleaned_title, '/', normalize-space($mods_doc/mods:mods/mods:name[1]/mods:namePart/text()), '/MusicRecording')), ' ', '_')" /></field>
              </xsl:if>
              <xsl:if test="$video">
                  <field name="url_label_str_stored">Watch Online</field>
                  <field name="pool_f">video</field>
                  <field name="work_title3_key_ssort"><xsl:value-of select="translate(lower-case(concat($cleaned_title, '//video')), ' ', '_')" /></field>
                  <field name="work_title2_key_ssort"><xsl:value-of select="translate(lower-case(concat($cleaned_title, '/', normalize-space($mods_doc/mods:mods/mods:name[1]/mods:namePart/text()), '/video')), ' ', '_')" /></field>
              </xsl:if>
              <!-- flat_broke_with_children_women_in_the_age_of_welfare_reform//video -->
              <field name="uva_availability_f_stored">On shelf</field>
              <field name="anon_availability_f_stored">On shelf</field>
              <field name="uva_availability_f_stored">Online</field>
              <field name="anon_availability_f_stored">Online</field>
              <field name="record_date_stored">
                  <xsl:value-of select="current-dateTime()"/>
              </field>
  
              <field name="doc_type_f_stored">avalon</field>
              <!--              <field name="source_facet">Libra2 Repository</field> -->
              <xsl:for-each select="doc[arr[@name='collection_ssim']]/str">
                  <field name="digital_collection_f_stored"><xsl:value-of select="."/></field>
              </xsl:for-each>
              <field name="data_source_f_stored">avalon</field>
              <!--             <field name="digital_collection_facet">Libra Repository</field>  -->
              <field name="location_f_stored">Internet Materials</field>
              <field name="shadowed_location_f_stored">
                  <xsl:choose>
                      <xsl:when test="bool[@name='hidden_bsi']/text() = 'true' ">
                          <xsl:text>HIDDEN</xsl:text>
                      </xsl:when>
                      <xsl:when test="date[@name='embargo_release_date_dtsi']">
                          <xsl:text>HIDDEN</xsl:text>
                      </xsl:when>
                      <xsl:otherwise>
                          <xsl:text>VISIBLE</xsl:text>
                      </xsl:otherwise>
                  </xsl:choose>
              </field>
              <field name="video_run_time_stored">
                  <xsl:variable name="runtime" >
                      <xsl:call-template name="runtime_fmt">
                          <xsl:with-param name="millis"><xsl:value-of select="number(str[@name='duration_ssi']/text())"/></xsl:with-param>
                      </xsl:call-template>
                  </xsl:variable>
                  <xsl:value-of select="$runtime" />
              </field>
              
              <xsl:for-each select="arr[@name='notes_tesim']/str">
                  <field name="notes_tsearch_stored"><xsl:value-of select="normalize-space(string(.))"/></field>
              </xsl:for-each>
              
              <xsl:if test="str[@name='summary_ssi']/text() != ''">
                  <field name="abstract_tsearch_stored"><xsl:value-of select="str[@name='summary_ssi']/text()" /></field>
              </xsl:if>
              <field name="date_indexed_f_stored"><xsl:call-template name="formatDateTime">
                  <xsl:with-param name="dateTime"><xsl:value-of select='current-dateTime()'/></xsl:with-param>
                  </xsl:call-template>
              </field>

              <field name="language_f_stored">
                  <xsl:value-of select="$lang_name"/>
              </field>
              <xsl:if test="str[@name='date_created_ssim']/text() != ''">
                  <xsl:variable name="dateCreated" select="str[@name='date_created_ssim']/text()" />
                  <field name="date_received_f_stored">
                      <xsl:call-template name="formatDate">
                          <xsl:with-param name="date" select="$dateCreated"/>
                      </xsl:call-template>
                  </field>
              </xsl:if> 
          </doc>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="runtime_fmt">
        <xsl:param name="millis"/>
        <xsl:variable name="seconds" select="floor($millis div 1000)"/>
        <xsl:value-of select="format-number(floor($seconds div 3600), '00')" />
        <xsl:value-of select="format-number(floor($seconds div 60) mod 60, ':00')"/>
        <xsl:value-of select="format-number($seconds mod 60, ':00')"/>
    </xsl:template>
    
    <xsl:template match="mods:titleInfo[@usage = 'primary']">
        <field name="title_tsearch_stored">
            <xsl:value-of select="mods:title"/>
        </field>
        <field name="full_title_tsearch_stored">
            <xsl:value-of select="mods:title"/>
        </field>
        <field name="title_ssort_stored">
            <xsl:value-of select="normalize-space(translate(mods:title, $uppercase, $lowercase))"/>
        </field>
    </xsl:template>

    <xsl:template match="mods:name">
        <xsl:variable name="name">
            <xsl:call-template name="stripParentheticRole">
                <xsl:with-param name="value" select="mods:namePart[1]"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="roleCode" select="mods:role/mods:roleTerm[@type = 'code']"/>
        
        <xsl:variable name="roleLabelParts">
            <xsl:apply-templates select="mods:role/mods:roleTerm[@type = 'text']" mode="string-join-mode"/>
        </xsl:variable>
        <xsl:variable name="roleLabel" select="lower-case($roleLabelParts)"/>
        <xsl:choose>
            <xsl:when test="$roleCode = 'drt'">
                <field name="author_director_tsearch_stored"><xsl:value-of select="$name" /></field>                
            </xsl:when>
            <xsl:when test="$roleCode = 'aut'">
                <field name="author_tsearchf_stored"><xsl:value-of select="$name" /></field>
            </xsl:when>
            <xsl:when test="$roleCode = 'prf'">
                <field name="performers_tsearch_stored"><xsl:value-of select="$name" /></field>
            </xsl:when>
            <xsl:otherwise>
                <field name="author_tsearchf_stored"><xsl:value-of select="concat($name, ' (', $roleLabel, ')')" /></field>
            </xsl:otherwise>
        </xsl:choose>
        <field name="author_added_entry_tsearch_stored"><xsl:value-of select="$name" /></field>
    </xsl:template>

    <xsl:template match="*" mode="string-join-mode">
        <xsl:apply-templates mode="string-join-mode"/>
    </xsl:template>    
    
    <xsl:template match="text()" mode="string-join-mode">
        <xsl:value-of select="."/>
    </xsl:template>
    <!--  // captured already above from summary_ssi
    <xsl:template match="mods:abstract">
        <field name="abstract_tsearch_stored">
            <xsl:value-of select="text()"/>
        </field>
    </xsl:template>  -->
    
    <xsl:template match="mods:accessCondition">
        <xsl:choose>
            <xsl:when test="contains(./text(), 'http')">
                <xsl:variable name="uri" select="concat('http', substring-before(substring-after(normalize-space(text()), 'http'), ' '))" />
                <field name="rights_url_a"><xsl:value-of select="$uri"/>"</field>
                <xsl:if test="starts-with($uri, 'http://rightsstatements.org')">
                    <field name="rs_uri_a"><xsl:value-of select="$uri"/></field>
                </xsl:if>
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
            </xsl:when>
        </xsl:choose>
        <field name="rights_tsearch_stored"><xsl:value-of select="text()"/></field>
    </xsl:template>

    <xsl:template match="mods:originInfo/mods:dateIssued">
<!--        <xsl:variable name="yearIssued" select="number(substring(text(), 1, 4))"/>
        <xsl:if test="number($yearIssued)">
            <field name="published_display_tsearch_stored">
                <xsl:value-of select="$yearIssued"/>
            </field>
            <field name="published_date">
                <xsl:value-of select="concat($yearIssued, '-01-01T00:00:00Z')"/>
            </field>
            <field name="published_daterange">
                <xsl:value-of select="$yearIssued"/>
            </field>
            <field name="published_display_a">
                <xsl:value-of select="$yearIssued"/>
            </field>
        </xsl:if>
-->     
        <xsl:if test="./text() != ''">
            <xsl:variable name="dateString" select="./text()"/>
            <xsl:call-template name="fixDate">
                <xsl:with-param name="field">published_daterange</xsl:with-param>
                <xsl:with-param name="datestring"><xsl:value-of select="$dateString" /></xsl:with-param>
                <xsl:with-param name="range">true</xsl:with-param>
            </xsl:call-template>
            <xsl:call-template name="fixDate">
                <xsl:with-param name="field">published_display_a</xsl:with-param>
                <xsl:with-param name="datestring"><xsl:value-of select="$dateString" /></xsl:with-param>
                <xsl:with-param name="range">true</xsl:with-param>
            </xsl:call-template>
            <xsl:call-template name="fixDate">
                <xsl:with-param name="field">published_date</xsl:with-param>
                <xsl:with-param name="datestring"><xsl:value-of select="$dateString" /></xsl:with-param>
                <xsl:with-param name="monthDefault">-01</xsl:with-param>
                <xsl:with-param name="dayDefault">-01</xsl:with-param>
                <xsl:with-param name="timeDefault">T00:00:00Z</xsl:with-param>
            </xsl:call-template>       
        </xsl:if>
   
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
    
    <xsl:template match="mods:originInfo/mods:dateCreated">
<!--        <field name="created_date_text">
            <xsl:value-of select="text()"/>
        </field>
        <field name="created_date_display">
            <xsl:value-of select="text()"/>
        </field>
-->        
    </xsl:template>
    
    <xsl:template match="mods:originInfo/mods:publisher">
        <field name="publisher_name_tsearch_stored">
            <xsl:value-of select="text()"/>
        </field>
    </xsl:template>
    
    <xsl:template match="mods:genre">
        <field name="topic_form_genre_tsearch_stored">
            <xsl:value-of select="text()"/>
        </field>
    </xsl:template>
    
    <xsl:template match="mods:subject/mods:topic">
        <field name="subject_tsearchf_stored">
            <xsl:value-of select="text()"/>
        </field>
    </xsl:template>
    
    <xsl:template match="mods:subject/mods:temporal">
        <field name="subject_era_tsearchf_stored">
            <xsl:value-of select="text()"/>
        </field>
    </xsl:template>
    
    <xsl:template match="mods:subject/mods:geographic">
        <field name="region_tsearchf_stored">
            <xsl:value-of select="text()"/>
        </field>
    </xsl:template>
    
    <xsl:template match="mods:relatedItem[@displayLabel]">
        <field name="url_supp_label_str_stored">
            <xsl:value-of select="@displayLabel"/>
        </field>
        <field name="url_supp_str_stored">
            <xsl:value-of select="mods:location/mods:url"/>
        </field>
    </xsl:template>
    
    <xsl:template match="mods:note">
        <field name="note_tsearch_stored">
            <xsl:value-of select="text()" />
        </field>
    </xsl:template>
    
    <xsl:template match="mods:tableOfContents">
        <field name="title_notes_tsearch_stored">
            <xsl:value-of select="text()" />
        </field>
    </xsl:template>
    
    <xsl:template match="mods:recordInfo/mods:recordChangeDate">
        <!-- record change date -->
    </xsl:template>
    
    <xsl:template name="stripParentheticRole">
        <xsl:param name="value" required="yes"/>
        <xsl:analyze-string select="$value" regex="^(.*) \([^(]+\)$">
            <xsl:matching-substring>
                <xsl:value-of select="regex-group(1)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="$value"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>

<!--    <xsl:template name="relatedNames">
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
    </xsl:template>-->
    
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
    
     
<!--    <xsl:template name="getFirstName">
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
    -->
<!--     <xsl:template name="year_multisort_publisheddatefacet">
        <xsl:param name="yearPub" />        
        <xsl:variable name="curDate" select="number(substring-before(string(current-date()), '-'))"/>
        <xsl:variable name="yearDiff" select="$curDate - $yearPub" />
        <field name="year_multisort_i">
            <xsl:value-of select="$yearPub" />
        </field>
    </xsl:template> -->
    
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
    
<!--    <xsl:template name="publisherinfo">
        <xsl:variable name="datestring" >
            <xsl:choose>
                <xsl:when test="matches(arr[@name='published_date_tesim']/str, '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:.*$')">
                    <xsl:value-of select="substring(arr[@name='published_date_tesim']/str, 1, 4)"/>
                </xsl:when>
                <xsl:when test="arr[@name='published_date_tesim']/str != ''">
                    <xsl:value-of select="arr[@name='published_date_tesim']/str"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring(arr[@name='date_created_tesim']/str , 1, 4)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="arr[@name='publisher_tesim']/str != ''">
                <xsl:value-of select="concat(arr[@name='publisher_tesim']/str, ', ', $datestring)" />
            </xsl:when>
        </xsl:choose>        
    </xsl:template>-->
    
<!--    <xsl:template name="publisheddate">
        <xsl:variable name="datestring" >
            <xsl:choose>
                <xsl:when test="matches(arr[@name='published_date_tesim']/str, '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:.*$')">
                    <xsl:value-of select="substring(arr[@name='published_date_tesim']/str, 1, 10)"/>
                </xsl:when>
                <xsl:when test="arr[@name='published_date_tesim']/str != ''">
                    <xsl:value-of select="arr[@name='published_date_tesim']/str"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring(replace(arr[@name='date_created_tesim']/str, '/', '-'), 1, 10)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$datestring" />
    </xsl:template>-->
    
<!--    <xsl:template name="publisheddatetime">
        <xsl:variable name="datetimestring" >
            <xsl:choose>
                <xsl:when test="matches(arr[@name='published_date_tesim']/str, '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:.*$')">
                    <xsl:value-of select="concat(substring(arr[@name='published_date_tesim']/str, 1, 17), '00Z')"/>
                </xsl:when>
                <xsl:when test="matches(arr[@name='published_date_tesim']/str, '\d{4}[-/]\d{2}[-/]-\d{2}')">
                    <xsl:value-of select="concat(replace(substring(arr[@name='published_date_tesim']/str, 1, 10), '/', '-'), 'T00:00:00Z')"/>
                </xsl:when>
                <xsl:when test="matches(arr[@name='published_date_tesim']/str, '\d{4}')">
                    <xsl:value-of select="concat(arr[@name='published_date_tesim']/str, '-01-01T00:00:00Z')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat(substring(replace(arr[@name='date_created_tesim']/str, '/', '-'), 1, 10),  'T00:00:00Z')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$datetimestring" />
    </xsl:template>
    
    <xsl:template name="publisheddateYYYY">
        <xsl:variable name="datestring" >
            <xsl:choose>
                <xsl:when test="matches(arr[@name='published_date_tesim']/str, '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:.*$')">
                    <xsl:value-of select="substring(arr[@name='published_date_tesim']/str, 1, 4)"/>
                </xsl:when>
                <xsl:when test="matches(arr[@name='published_date_tesim']/str, '.*\d{4}.*')">
                    <xsl:analyze-string select="arr[@name='published_date_tesim']/str" regex=".*(\d\d\d\d).*">
                        <xsl:matching-substring>
                            <xsl:value-of select="regex-group(1)"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring(arr[@name='date_created_tesim']/str , 1, 4)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$datestring"/>    
    </xsl:template>
-->
    <!-- handles fixing all of the dates. Can create a date or a daterange -->
<!--    <xsl:template name="fixDate">
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
                    <!-\-   <xsl:value-of select="concat('%%%%%', $datestring, '%%%%%')"/> -\->
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="$fmtdate != ''">
            <xsl:element name="field">
                <xsl:attribute name="name"><xsl:value-of select="$field"/></xsl:attribute>
                <xsl:value-of select="$fmtdate" />
            </xsl:element>
        </xsl:if>
    </xsl:template>-->

</xsl:stylesheet>
