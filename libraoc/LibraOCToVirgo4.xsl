<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:l="http://language.data">
    <xsl:output indent="yes" />
    <xsl:variable name="urlbase" select="string('https://doi.org/')" />
    
    <xsl:template match='/'>
        
        <xsl:for-each select="/response/result">
            <add>
                <!--                 <xsl:for-each select="doc"> -->
                <xsl:for-each select="doc[arr[@name='has_model_ssim']/str = 'LibraWork']">
            <doc>
                <xsl:variable name="isThesis">
                    <xsl:call-template name="isThesis">
                        <xsl:with-param name="worktype" select="arr[@name='work_type_tesim']/str" />
                    </xsl:call-template>
                </xsl:variable>
                <field name="id"><xsl:value-of select="concat('oc_', str[@name='id'])" /></field>
                <!--             <field name="digital_collection_f_stored">Libra Repository</field>  -->
                <field name="doc_type_f_stored">libra</field>
                <!--              <field name="source_facet">Libra2 Repository</field> -->
                <field name="source_f_stored">Libra Repository</field>
                <field name="digital_collection_f_stored">Libra Open Repository</field>
                <field name="data_source_f_stored">libraoc</field>
                <field name="pool_f_stored">thesis</field>
                <!--             <field name="digital_collection_facet">Libra Repository</field>  -->
		<xsl:variable name="additional_pool">
                    <xsl:choose>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Article'" >
                            <xsl:text></xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Audio'" >
                            <xsl:text>sound_recordings</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Book'" >
                            <xsl:text>catalog</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Conference Proceeding'" >
                            <xsl:text></xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Image'" >
                            <xsl:text>Visual Materials</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Journals'" >
                            <xsl:text>serials</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Map or Cartographic Material'" >
                            <xsl:text>maps</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Part of Book'" >
                            <xsl:text>catalog</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Poster'" >
                            <xsl:text></xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Presentation'" >
                            <xsl:text></xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Project'" >
                            <xsl:text></xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Report'" >
                            <xsl:text></xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Research Paper'" >
                            <xsl:text></xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Video'" >
                            <xsl:text>video</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Other'" >
                            <xsl:text></xsl:text>
                        </xsl:when>
                    </xsl:choose>
		</xsl:variable>
                <xsl:if test="not($additional_pool = '')">
                    <field name="pool_f_stored"><xsl:value-of select="$additional_pool"/> </field>
                </xsl:if>
                <field name="location_f_stored">Internet Materials</field>
                <field name="shadowed_location_f_stored">
                    <xsl:choose>
                        <xsl:when test="arr[@name='read_access_group_ssim']/str = 'public' or arr[@name='read_access_group_ssim']/str = 'registered' ">
                            <xsl:text>VISIBLE</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>HIDDEN</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </field>
                <field name="uva_availability_f_stored">Online</field>
                <field name="anon_availability_f_stored">Online</field>
                <xsl:if test="arr[@name='published_date_tesim']/str != ''">
                    <xsl:call-template name="fixDate">
                        <xsl:with-param name="field">published_daterange</xsl:with-param>
                        <xsl:with-param name="datestring"><xsl:value-of select="arr[@name='published_date_tesim']/str" /></xsl:with-param>
                        <xsl:with-param name="range">true</xsl:with-param>
                    </xsl:call-template>
                    <xsl:call-template name="fixDate">
                        <xsl:with-param name="field">published_display_a</xsl:with-param>
                        <xsl:with-param name="datestring"><xsl:value-of select="arr[@name='published_date_tesim']/str" /></xsl:with-param>
                        <xsl:with-param name="range">true</xsl:with-param>
                    </xsl:call-template>
                    <xsl:call-template name="fixDate">
                        <xsl:with-param name="field">published_date</xsl:with-param>
                        <xsl:with-param name="datestring"><xsl:value-of select="arr[@name='published_date_tesim']/str" /></xsl:with-param>
                        <xsl:with-param name="monthDefault">-01</xsl:with-param>
                        <xsl:with-param name="dayDefault">-01</xsl:with-param>
                        <xsl:with-param name="timeDefault">T00:00:00Z</xsl:with-param>
                    </xsl:call-template>
                </xsl:if>
                <field name="published_tsearch_stored">
                    <xsl:call-template name="publisherinfo"/>
                </field>
                <field name="title_tsearch_stored"><xsl:value-of select="arr[@name='title_tesim']/str[1]" /></field>
                <field name="title_ssort_stored"><xsl:call-template name="cleantitle" >
                    <xsl:with-param name="title" select="arr[@name='title_tesim']/str[1]"/>
                    <xsl:with-param name="language" select="arr[@name='language_tesim']/str"/>
                    </xsl:call-template></field>
                <xsl:for-each select="arr[@name='mods_journal_title_info_t']">
                    <field name="journal_title_tsearch_stored">
                        <xsl:value-of select="str" />
                    </field>
                </xsl:for-each> 
                <field name="work_title2_key_ssort_stored">
                    <xsl:variable name="title">
                        <xsl:call-template name="cleantitle" >
                            <xsl:with-param name="title" select="arr[@name='title_tesim']/str[1]"/>
                            <xsl:with-param name="language" select="arr[@name='language_tesim']/str"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:variable name="author">
                        <xsl:value-of select="arr[@name='authors_tesim'][1]/str"/>
                    </xsl:variable>
                    <xsl:variable name="firstName">
                        <xsl:value-of select="substring-before(substring-after($author, 'first_name&quot;:&quot;'), '&quot;')"/>
                    </xsl:variable>
                    <xsl:variable name="lastName">
                        <xsl:value-of select="substring-before(substring-after($author, 'last_name&quot;:&quot;'), '&quot;')"/>
                    </xsl:variable>
                    <xsl:value-of select="replace(lower-case($title), '[- ]+', '_')"/><xsl:text>/</xsl:text><xsl:value-of select="replace(lower-case($lastName),'[ ]+','_')"/>
                    <xsl:text>_</xsl:text><xsl:value-of select="replace(lower-case($firstName),'[ ]+','_')"/><xsl:text>/Thesis</xsl:text>
                </field>
                
                <field name="work_title3_key_ssort_stored">
                    <xsl:variable name="title">
                        <xsl:call-template name="cleantitle" >
                            <xsl:with-param name="title" select="arr[@name='title_tesim']/str[1]"/>
                            <xsl:with-param name="language" select="arr[@name='language_tesim']/str"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:variable name="author">
                        <xsl:value-of select="arr[@name='authors_tesim'][1]/str"/>
                    </xsl:variable>
                    <xsl:variable name="firstName">
                        <xsl:value-of select="substring-before(substring-after($author, 'first_name&quot;:&quot;'), '&quot;')"/>
                    </xsl:variable>
                    <xsl:variable name="lastName">
                        <xsl:value-of select="substring-before(substring-after($author, 'last_name&quot;:&quot;'), '&quot;')"/>
                    </xsl:variable>
                    <xsl:value-of select="replace(lower-case($title), '[- ]+', '_')"/><xsl:text>/</xsl:text><xsl:value-of select="replace(lower-case($lastName),'[ ]+','_')"/>
                    <xsl:text>_</xsl:text><xsl:value-of select="replace(lower-case($firstName),'[ ]+','_')"/><xsl:text>/Thesis</xsl:text>
                </field>
                
                <!--  stuff for authors -->
                <xsl:for-each select="distinct-values(arr[@name = 'authors_tesim']/str)">
                    <xsl:sort select="translate(substring-before(substring-after(., 'index&quot;:'), ','), '\&quot;', '')" />
                    <xsl:variable name="isNoneProvided">
                        <xsl:call-template name="isNoneProvided">
                            <xsl:with-param name="value" select="." />
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:variable name="firstName">
                        <xsl:value-of select="substring-before(substring-after(., 'first_name&quot;:&quot;'), '&quot;')"/>
                    </xsl:variable>
                    <xsl:variable name="lastName">
                        <xsl:value-of select="substring-before(substring-after(., 'last_name&quot;:&quot;'), '&quot;')"/>
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
                
                <!--  stuff for contributors -->
                <xsl:for-each select="distinct-values(arr[@name = 'contributors_tesim']/str)">
                    <xsl:sort select="translate(substring-before(substring-after(., 'index&quot;:'), ','), '\&quot;', '')" />
                    <xsl:variable name="isNoneProvided">
                        <xsl:call-template name="isNoneProvided">
                            <xsl:with-param name="value" select="." />
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:variable name="firstName">
                        <xsl:value-of select="substring-before(substring-after(., 'first_name&quot;:&quot;'), '&quot;')"/>
                    </xsl:variable>
                    <xsl:variable name="lastName">
                        <xsl:value-of select="substring-before(substring-after(., 'last_name&quot;:&quot;'), '&quot;')"/>
                    </xsl:variable>
                    <xsl:variable name="institutionName">
                        <xsl:value-of select="substring-before(substring-after(., 'institution&quot;:&quot;'), '&quot;')" />
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$isThesis = 'true' and  $isNoneProvided != 'true'" >
                            <field name="creator_a">
                                <xsl:call-template name="lastcommafirst">
                                    <xsl:with-param name="first" select="$firstName"/>
                                    <xsl:with-param name="last" select="$lastName"/>
                                </xsl:call-template>
                            </field>
                            <field name="author_added_entry_tsearch_stored" >
                                <xsl:value-of select="$firstName" /><xsl:text> </xsl:text><xsl:value-of select="$lastName"/>
                            </field>
   <!--                         <field name="author_facet">
                                <xsl:call-template name="lastcommafirst">
                                    <xsl:with-param name="first" select="$firstName"/>
                                    <xsl:with-param name="last" select="$lastName"/>
                                </xsl:call-template>
                            </field> -->
                        </xsl:when>
                        <xsl:when test="$isThesis != 'true' and  $isNoneProvided != 'true'" >
                            <field name="ctb_a">
                                <xsl:call-template name="lastcommafirst">
                                    <xsl:with-param name="first" select="$firstName"/>
                                    <xsl:with-param name="last" select="$lastName"/>
                                </xsl:call-template>
                            </field>
                            <field name="author_added_entry_tsearch_stored" >
                                <xsl:value-of select="$firstName" /><xsl:text> </xsl:text><xsl:value-of select="$lastName"/>
                            </field>
<!--                            <field name="author_facet">
                                <xsl:call-template name="lastcommafirst">
                                    <xsl:with-param name="first" select="$firstName"/>
                                    <xsl:with-param name="last" select="$lastName"/>
                                </xsl:call-template>
                            </field> -->
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
                
                <!--  stuff for related_names -->
 <!--               <xsl:variable name="relatedNames" >
                    <xsl:call-template name="relatedNames">
                        <xsl:with-param name="authors"><xsl:value-of select="arr[@name = 'authors_tesim']" /></xsl:with-param>
                        <xsl:with-param name="contributors"><xsl:value-of select="arr[@name = 'contributors_tesim']" /></xsl:with-param>
                    </xsl:call-template>
                </xsl:variable>
                -->
 <!--               <xsl:for-each select="distinct-values(substring-after(arr[@name = 'authors_tesim']/str | arr[@name = 'contributors_tesim']/str , 'index&quot;:'))">-->
 <!--               <xsl:for-each select="distinct-values(tokenize($relatedNames, '###'))">
                    
                    <xsl:variable name="isNoneProvided">
                        <xsl:call-template name="isNoneProvided">
                            <xsl:with-param name="value" select="." />
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:variable name="firstName">
                        <xsl:value-of select="substring-before(substring-after(., 'first_name&quot;:&quot;'), '&quot;')"/>
                    </xsl:variable>
                    <xsl:variable name="lastName">
                        <xsl:value-of select="substring-before(substring-after(., 'last_name&quot;:&quot;'), '&quot;')"/>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$firstName != ''" >
                            <field name="author_f">
                                <xsl:call-template name="lastcommafirst">
                                    <xsl:with-param name="first" select="$firstName"/>
                                    <xsl:with-param name="last" select="$lastName"/>
                                </xsl:call-template>
                            </field>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each> -->

                <xsl:for-each select="distinct-values(arr[@name='authors_tesim']/str)">
                    <xsl:if test="substring-before(substring-after(., 'index&quot;:&quot;'), '&quot;') = '0'">
                        <field name="author_ssort_stored">
                            <xsl:value-of select="lower-case(substring-before(substring-after(., 'last_name&quot;:&quot;'), '&quot;'))"/>
                            <xsl:text> </xsl:text>
                            <xsl:value-of select="lower-case(substring-before(substring-after(., 'first_name&quot;:&quot;'), '&quot;'))"/>
                        </field>
                    </xsl:if>
                </xsl:for-each>

                <xsl:for-each select="arr[@name='notes_tesim']/str">
                    <field name="note_tsearch_stored"><xsl:value-of select="normalize-space(string(.))"/></field>
                </xsl:for-each>
                
                <xsl:choose>
                    <xsl:when test="arr[@name='language_tesim']">
                        <xsl:for-each select="arr[@name='language_tesim']/str">
                             <field name="language_f_stored"><xsl:value-of select="."/></field>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <field name="language_f_stored">English</field>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="arr[@name='description_tesim']/str != '' and arr[@name='description_tesim']/str != 'Enter your description here'">
                    <field name="abstract_tsearch_stored"><xsl:value-of select="arr[@name='description_tesim']/str" /></field>
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
                    
                <xsl:choose>
                    <xsl:when test="contains(arr[@name='doi_tesim']/str, 'doi:')">
                        <field name="url_str_stored">
                            <xsl:value-of select="concat($urlbase, substring-after(arr[@name='doi_tesim']/str, 'doi:'))"/>
                        </field>
                        <field name="url_label_str_stored">
                            <xsl:text>Access Online</xsl:text>
                        </field>
                    </xsl:when>
                    <xsl:otherwise>
                        <field name="url_str_stored">
                            <xsl:value-of select="concat($urlbase, arr[@name='doi_tesim']/str)"/>
                        </field>
                        <field name="url_label_str_stored">
                            <xsl:text>Access Online</xsl:text>
                        </field>
                    </xsl:otherwise>
                </xsl:choose>
                
                <xsl:for-each select="distinct-values(arr[@name='related_url_tesim']/str)">
                    <xsl:if test="contains(. , '.')" >
                        <field name="url_supp_str_stored">
                            <xsl:value-of select="."/>
                        </field>
                        <field name="url_supp_label_str_stored">
                            <xsl:value-of select="'Related Materials'"/>
                        </field>
                    </xsl:if>
                </xsl:for-each>
                <xsl:if test="arr[@name='thumbnail_url_display_ssm']/str != ''">
                    <field name="thumbnail_url_a"><xsl:value-of select="arr[@name='thumbnail_url_display_ssm']/str"/></field>
                </xsl:if>
                <xsl:for-each select="distinct-values(arr[@name='sponsoring_agency_tesim']/str)">
                    <field name="sponsoring_agency_tsearch_stored"><xsl:value-of select="."/></field>
                </xsl:for-each>
                <xsl:for-each select="distinct-values(arr[@name='rights_display_ssm']/str)">
                    <field name="rights_tsearchf_stored"><xsl:value-of select="."/></field>
                </xsl:for-each>
                <xsl:if test="not(arr[@name='rights_url_ssm']/str)">
                    <field name="rs_uri_a">http://rightsstatements.org/vocab/InC/1.0/</field>
                </xsl:if>
                <xsl:for-each select="distinct-values(arr[@name='rights_url_ssm']/str)">
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
                
                <!--                
                <xsl:call-template name="dataverse">
                    <xsl:with-param name="libra-id"><xsl:value-of select="string(./str[@name='id'])"/></xsl:with-param>
                </xsl:call-template>                    
-->                
                
 <!--               <xsl:variable name="pid" select="concat('info:fedora/', string(./str[@name='id']))"/>
                <xsl:for-each select="/response/result/doc[arr[@name='has_model_s']/str='info:fedora/afmodel:FileAsset' and arr[@name='is_part_of_s']/str = $pid]/str[@name='id']">
                    <field name="url_display">
                          <xsl:value-of select="concat($urlbase, 'file_assets/', string(.), '||Full Text Document')"/>
                    </field>
                </xsl:for-each> -->
                <field name="format_f_stored">
                    <xsl:choose>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Article'" >
                            <xsl:text>Article</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Audio'" >
                            <xsl:text>Streaming Audio</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Book'" >
                            <xsl:text>Book</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Conference Proceeding'" >
                            <xsl:text>Conference Paper</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Image'" >
                            <xsl:text>Visual Materials</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Map or Cartographic Material'" >
                            <xsl:text>Map</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Part of Book'" >
                            <xsl:text>Book Chapter</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Poster'" >
                            <xsl:text>Visual Materials</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Presentation'" >
                            <xsl:text>Visual Materials</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Project'" >
                            <xsl:text>Working Paper</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Report'" >
                            <xsl:text>Technical report</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Research Paper'" >
                            <xsl:text>Working Paper</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Video'" >
                            <xsl:text>Streaming Video</xsl:text>
                        </xsl:when>
                        <xsl:when test="arr[@name='resource_type_tesim']/str = 'Other'" >
                            <xsl:text>Other Media</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </field>
                <field name="format_orig_tsearch_stored">
                    <xsl:value-of select="arr[@name='resource_type_tesim']/str"/>
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
    
    <xsl:template name="publisherinfo">
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
    </xsl:template>
    
    <xsl:template name="publisheddate">
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
    </xsl:template>
    
    <xsl:template name="publisheddatetime">
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

</xsl:stylesheet>
