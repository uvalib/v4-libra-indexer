<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:l="http://language.data">
    <xsl:output indent="yes" />
    <xsl:variable name="urlbase" select="string('https://dataverse.lib.virginia.edu/dataset.xhtml')" />

    <xsl:key name="dataverse-lookup" match="entry" use="libra"/>
    <xsl:variable name="dataverse-map" select="document('LibraToDataverseMap.xml')/dataversemap"/>
    <xsl:variable name="dataverse-url" select="document('LibraToDataverseMap.xml')/dataversemap/urlbase/text()"/>
    <xsl:variable name="dataverse-thumbnail-url" select="string('https://coverimagestest.lib.virginia.edu/cover_images/libra')"/>
    
    <xsl:template match='/'>

        <xsl:for-each select="/response/result">
            <add>
                <!--                 <xsl:for-each select="doc"> -->
                <xsl:for-each select="doc">
            <doc>
                <field name="id"><xsl:value-of select="str[@name='id']" /></field>
                <field name="source_f_stored">Libra Repository</field>
                <field name="doc_type_f_stored">dataverse</field>
                <field name="digital_collection_f_stored">Libra Data Repository</field>
                <field name="location_f_stored">Internet Materials</field>
                <field name="thumbnail_url_a"><xsl:value-of select="$dataverse-thumbnail-url"/></field>
                <field name="date_indexed_f_stored"><xsl:call-template name="formatDateTime">
                    <xsl:with-param name="dateTime"><xsl:value-of select='current-dateTime()'/></xsl:with-param>
                    </xsl:call-template>
                </field>
                <field name="data_source_f_stored">libradata</field>
                <field name="pool_f_stored">thesis</field>
                
                <field name="shadowed_location_f_stored">
                    <xsl:choose>
                        <xsl:when test="arr[@name='publicationStatus']/str = 'Published'">
                            <xsl:text>VISIBLE</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>HIDDEN</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </field>
                <field name="uva_availability_f_stored">Online</field>
                <field name="anon_availability_f_stored">Online</field>
                <xsl:variable name="yearPub" >                     
                    <xsl:choose>
                        <xsl:when test="starts-with(str[@name='notesText']/text(), 'Dataset originally deposited on ')">
                            <xsl:value-of select="substring-before(substring-after(str[@name='notesText'], 'Dataset originally deposited on '), '-')" />
                        </xsl:when>
                        <xsl:when test="str[@name='distributionDate'] != ''">
                            <xsl:value-of select="str[@name='distributionDate']" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="substring-before(date[@name='dateSort'], '-')" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
               
                 <xsl:variable name="published_date_a">
                    <xsl:choose>
                        <xsl:when test="starts-with(str[@name='notesText']/text(), 'Dataset originally deposited on ')">
                            <xsl:value-of select="substring-before(substring-after(str[@name='notesText'], 'Dataset originally deposited on '), ' as ')" />
                        </xsl:when>
                        <xsl:when test="str[@name='distributionDate'] != ''">
                            <xsl:value-of select="str[@name='distributionDate']" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="substring-before(date[@name='dateSort'], 'T')" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:if test="$published_date_a != ''">
                    <xsl:call-template name="fixDate">
                        <xsl:with-param name="field">published_daterange</xsl:with-param>
                        <xsl:with-param name="datestring"><xsl:value-of select="$published_date_a" /></xsl:with-param>
                        <xsl:with-param name="range">true</xsl:with-param>
                    </xsl:call-template>
                    <xsl:call-template name="fixDate">
                        <xsl:with-param name="field">published_display_a</xsl:with-param>
                        <xsl:with-param name="datestring"><xsl:value-of select="$published_date_a" /></xsl:with-param>
                        <xsl:with-param name="range">true</xsl:with-param>
                    </xsl:call-template>
                    <xsl:call-template name="fixDate">
                        <xsl:with-param name="field">published_date</xsl:with-param>
                        <xsl:with-param name="datestring"><xsl:value-of select="$published_date_a" /></xsl:with-param>
                        <xsl:with-param name="monthDefault">-01</xsl:with-param>
                        <xsl:with-param name="dayDefault">-01</xsl:with-param>
                        <xsl:with-param name="timeDefault">T00:00:00Z</xsl:with-param>
                    </xsl:call-template>       
                </xsl:if>
                
                <field name="production_date_a">
                    <xsl:choose>
                        <xsl:when test="str[@name='productionDate'] != ''">
                            <xsl:value-of select="str[@name='productionDate']" />
                        </xsl:when>
                        <xsl:when test="starts-with(str[@name='notesText']/text(), 'Dataset originally deposited on ')">
                            <xsl:value-of select="replace(substring-before(substring-after(str[@name='notesText'], 'Dataset originally deposited on '), ' as '), '-', '')" />
                        </xsl:when>
                        <xsl:when test="str[@name='distributionDate'] != ''">
                            <xsl:value-of select="str[@name='distributionDate']" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="substring-before(date[@name='dateSort'], 'T')" />
                        </xsl:otherwise>
                    </xsl:choose>
                </field>
                <field name="date_received_f_stored">
                    <xsl:choose>
                        <xsl:when test="starts-with(str[@name='notesText']/text(), 'Dataset originally deposited on ')">
                            <xsl:value-of select="replace(substring-before(substring-after(str[@name='notesText'], 'Dataset originally deposited on '), ' as '), '-', '')" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="replace(substring-before(date[@name='dateSort'], 'T'), '-', '')" />
                        </xsl:otherwise>
                    </xsl:choose>
                </field>

                <field name="published_tsearch_stored">
                    <xsl:variable name="pubDate">
                        <xsl:choose>
                            <xsl:when test="starts-with(str[@name='notesText']/text(), 'Dataset originally deposited on ')">
                                <xsl:value-of select="substring-before(substring-after(str[@name='notesText'], 'Dataset originally deposited on '), ' as ')" />
                            </xsl:when>
                            <xsl:when test="str[@name='distributionDate'] != ''">
                                <xsl:value-of select="str[@name='distributionDate']" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="substring-before(date[@name='dateSort'], 'T')" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="arr[@name='producerName']/str[1] != '' and arr[@name='producerAffiliation']/str[1] != ''">
                            <xsl:value-of select="concat(arr[@name='producerName']/str[1], ', ', arr[@name='producerAffiliation']/str[1], ', ', $pubDate)" />
                        </xsl:when>
                        <xsl:when test="arr[@name='producerName']/str[1] != '' and arr[@name='producerAffiliation']/str[1] = ''">
                            <xsl:value-of select="concat(arr[@name='producerName']/str[1], ', ', $pubDate)" />
                        </xsl:when>
                        <xsl:when test="arr[@name='producerName']/str[1] = '' and arr[@name='producerAffiliation']/str[1] != ''">
                            <xsl:value-of select="concat(arr[@name='producerAffiliation']/str[1], ', ', $pubDate)" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat('University of Virginia', ', ', $pubDate)" />
                        </xsl:otherwise>
                    </xsl:choose>
                </field>
                <xsl:if test="arr[@name='dsDescriptionValue']/str != '' and arr[@name='dsDescriptionValue']/str != 'Enter your description here'">
                    <field name="abstract_tsearch_stored"><xsl:value-of select="arr[@name='dsDescriptionValue']/str" /></field>
                </xsl:if>
                
                <field name="title_tsearch_stored"><xsl:value-of select="str[@name='title']" /></field>
                <field name="title_ssort_stored"><xsl:call-template name="cleantitle" >
                    <xsl:with-param name="title" select="str[@name='title']"/>
                    <xsl:with-param name="language" select="arr[@name='language']/str"/>
                    </xsl:call-template></field>
           <!--     <xsl:for-each select="arr[@name='mods_journal_title_info_t']">
                    <field name="journal_title_tsearch_stored">
                        <xsl:value-of select="str" />
                    </field>
                </xsl:for-each> -->
                <!--  stuff for authors -->
                <xsl:for-each select="arr[@name='authorName']/str">
                    <field name="author_tsearchf_stored">
                        <xsl:value-of select="."/>
                    </field>                    
                <!--    <field name="author_tsearch_stored" >
                        <xsl:call-template name="firstspacelast">
                            <xsl:with-param name="fullname" select="text()"/>
                            <xsl:with-param name="tolower" select="'false'"/>
                        </xsl:call-template>
                    </field> --> 
                </xsl:for-each>
                <xsl:for-each select="arr[@name='authorName']/str">
                    <field name="author_facet_f_stored" >
                        <xsl:call-template name="firstspacelastcommaaffil">
                            <xsl:with-param name="fullname" select="text()"/>
                            <xsl:with-param name="affiliationSet" select="(../../arr[@name='authorAffiliation']/str)"/>
                            <xsl:with-param name="index" select="count(preceding-sibling::str)+1"></xsl:with-param>
                        </xsl:call-template>
                    </field>
                </xsl:for-each>

                <xsl:for-each select="arr[@name='grantNumberAgency']/str">
                    <field name="grant_info_a" >
                        <xsl:call-template name="grantInfo">
                            <xsl:with-param name="agency" select="text()"/>
                            <xsl:with-param name="grantNumSet" select="(../../arr[@name='grantNumberValue']/str)"/>
                            <xsl:with-param name="index" select="count(preceding-sibling::str)+1"></xsl:with-param>
                        </xsl:call-template>
                    </field>
                </xsl:for-each>
                
                <field name="work_title2_key_ssort_stored">
                    <xsl:variable name="title">
                        <xsl:call-template name="cleantitle" >
                            <xsl:with-param name="title" select="str[@name='title']"/>
                            <xsl:with-param name="language">
                                <xsl:call-template name="languageLookup">
                                    <xsl:with-param name="curAbb" select="."/>
                                </xsl:call-template>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:value-of select="replace(lower-case($title), '[- ]+', '_')"/><xsl:text>/</xsl:text><xsl:value-of select="replace(lower-case(arr[@name='authorName']/str[1]),'[, ]+','_')"/>
                    <xsl:value-of select="replace(lower-case(arr[@name='author_first_name_tesim']/str[1]),'[ ]+','_')"/><xsl:text>/Dataset</xsl:text>
                </field>
                
                <xsl:for-each select="arr[@name='authorName']/str[1]">
                    <field name="author_ssort_stored">
                        <xsl:choose>
                            <xsl:when test="contains(text(), '&amp;')" >
                                <xsl:call-template name="firstspacelastcommaetc">
                                    <xsl:with-param name="allnames" select="text()"/>
                                    <xsl:with-param name="tolower" select="'true'"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="replace(lower-case(text()), '[, .]+', ' ')"/>
                            </xsl:otherwise>
                        </xsl:choose>
                     </field>
                </xsl:for-each>
                <!-- stuff for contributors and producers -->
                <xsl:for-each select="arr[@name='producerName']/str">
                    <field name="creator_a">
                        <xsl:value-of select="."/>
                    </field>
                    <field name="author_added_entry_tsearch_stored" >
                        <xsl:value-of select="."/>
                    </field>
                </xsl:for-each>
                <xsl:for-each select="arr[@name='contributorName']/str">
                    <field name="creator_a">
                        <xsl:value-of select="."/>
                    </field>
                    <field name="author_added_entry_tsearch_stored" >
                        <xsl:value-of select="."/>
                    </field>
                </xsl:for-each>
                
                <xsl:for-each select="str[@name='language']">
                    <field name="language_f_stored"><xsl:call-template name="languageLookup">
                        <xsl:with-param name="curAbb" select="."/>
                    </xsl:call-template>
                    </field>
                </xsl:for-each>

                <xsl:if test="arr[@name='keywordValue']/str != ''">
                    <xsl:for-each select="arr[@name='keywordValue']/str">
                        <field name="subject_tsearchf_stored"><xsl:value-of select="replace(., '^\s*(.+?)\s*$', '$1')"/></field>
                    </xsl:for-each>
                </xsl:if>

                <xsl:if test="str[@name='notesText'] != ''">
                    <field name="note_tsearch_stored"><xsl:value-of select="str[@name='notesText']"/></field>
                </xsl:if>

                <xsl:choose>
                    <xsl:when test="./str[@name='parentId'] = '221' and contains(./str[@name='alternativeURL']/text(), '&gt;') ">
                        <field name="url_str_stored">
                            <xsl:value-of select="substring-before(substring-after(./str[@name='alternativeURL']/text(), '&gt;'), '&lt;')"/>
                        </field>
                        <field name="url_supp_str_stored">
                            <xsl:value-of select="$urlbase, '?persistentId=', string(./str[@name='identifier'])"/>
                        </field>
                        <field name="url_label_str_stored">
                            <xsl:value-of select="'Access Online'"/>
                        </field>
                        <field name="url_label_supp_str_stored">
                            <xsl:value-of select="'Access Raw Data Files'"/>
                        </field>
                    </xsl:when>
                    <xsl:when test="./str[@name='parentId'] = '221' and ./str[@name='alternativeURL']/text() !=  '' ">
                        <field name="url_str_stored">
                            <xsl:value-of select="./str[@name='alternativeURL']/text()"/>
                        </field>
                        <field name="url_supp_str_stored">
                            <xsl:value-of select="concat($urlbase, '?persistentId=', string(./str[@name='identifier']))"/>
                        </field>
                        <field name="url_label_str_stored">
                            <xsl:value-of select="'Access Online'"/>
                        </field>
                        <field name="url_label_supp_str_stored">
                            <xsl:value-of select="'Access Raw Data Files'"/>
                        </field>
                    </xsl:when>
                    <xsl:otherwise>
                        <field name="url_str_stored">
                            <xsl:value-of select="concat($urlbase, '?persistentId=', string(./str[@name='identifier']))"/>
                        </field>
                        <field name="url_label_str_stored">
                            <xsl:value-of select="'Access Online'"/>
                        </field>
                    </xsl:otherwise>
                </xsl:choose>
                
                <xsl:call-template name="dataverse">
                    <xsl:with-param name="libra-id"><xsl:value-of select="string(./str[@name='id'])"/></xsl:with-param>
                </xsl:call-template>

                <xsl:if test="arr[@name='relatedMaterial' or @name='relatedDatasets']/str != ''">
                    <xsl:for-each select="arr[@name='relatedMaterial' or @name='relatedDatasets']/str">
                        <field name="url_supp_str_stored">
                            <xsl:call-template name="suppurl">
                                <xsl:with-param name="suppstr" select="text()"/>
                            </xsl:call-template>
                        </field>
                        <field name="url_label_supp_str_stored">
                            <xsl:call-template name="suppurllabel">
                                <xsl:with-param name="suppstr" select="text()"/>
                            </xsl:call-template>
                        </field>
                    </xsl:for-each>
                </xsl:if>
                <xsl:if test="./str[@name='parentId'] != '221' and str[@name='alternativeURL'] != ''">
                    <field name="url_supp_str_stored">
                        <xsl:call-template name="suppurl">
                            <xsl:with-param name="suppstr" select="str[@name='alternativeURL']/text()"/>
                        </xsl:call-template>
                    </field>
                    <field name="url_label_supp_str_stored">
                        <xsl:call-template name="suppurllabel">
                            <xsl:with-param name="suppstr" select="str[@name='alternativeURL']/text()"/>
                        </xsl:call-template>
                    </field>
                </xsl:if>
                
 <!--               <xsl:variable name="pid" select="concat('info:fedora/', string(./str[@name='id']))"/>
                <xsl:for-each select="/response/result/doc[arr[@name='has_model_s']/str='info:fedora/afmodel:FileAsset' and arr[@name='is_part_of_s']/str = $pid]/str[@name='id']">
                    <field name="url_a">
                          <xsl:value-of select="concat($urlbase, 'file_assets/', string(.), '||Full Text Document')"/>
                    </field>
                </xsl:for-each> -->
                <field name="format_f_stored">
                    <xsl:text>Computer Resource</xsl:text>
                </field>
                <field name="format_f_stored">
                    <xsl:text>Online</xsl:text>
                </field>
                <xsl:choose>
                    <xsl:when test="./str[@name='parentId'] = '221'">                            
                        <field name="format_f_stored">
                            <xsl:text>Dataset</xsl:text>
                        </field>
                    </xsl:when>
                     <xsl:otherwise>
                         <field name="format_f_stored">
                             <xsl:text>Dataset</xsl:text>
                         </field>
                     </xsl:otherwise>
                </xsl:choose>
                
             </doc>
        </xsl:for-each>
        </add>
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
        <xsl:param name="dateTime" />
        <xsl:variable name="date" select="substring-before($dateTime, 'T')" />
        <xsl:variable name="year" select="substring-before($date, '-')" />
        <xsl:variable name="month" select="substring-before(substring-after($date, '-'), '-')" />
        <xsl:variable name="day" select="substring-after(substring-after($date, '-'), '-')" />
        <xsl:value-of select="concat($year, $month, $day)" />
    </xsl:template>

    <xsl:template name="languageLookup">
        <xsl:param name="curAbb"/>
        <xsl:choose>
            <xsl:when test="$curAbb='eng'"><xsl:text>English</xsl:text></xsl:when>
            <xsl:when test="$curAbb='fre'"><xsl:text>French</xsl:text></xsl:when>
            <xsl:when test="$curAbb='ita'"><xsl:text>Italian</xsl:text></xsl:when>
            <xsl:when test="$curAbb='spa'"><xsl:text>Spanish</xsl:text></xsl:when>
            <xsl:when test="$curAbb='ger'"><xsl:text>German</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>Unknown</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="firstspacelast">
        <xsl:param name="fullname"/>
        <xsl:param name="tolower"/>
        <xsl:variable name="lastname" select="substring-before($fullname, ',')" />
        <xsl:variable name="firstname" select="replace($fullname, '[^,]+,[ ]*', '')" />
        <xsl:choose>
            <xsl:when test="$tolower = 'true'"><xsl:value-of select="lower-case(concat($firstname, ' ', $lastname))" /></xsl:when>
            <xsl:otherwise><xsl:value-of select="concat($firstname, ' ', $lastname)" /></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="firstspacelastcommaetc">
        <xsl:param name="allnames"/>
        <xsl:param name="tolower"/>
        <xsl:variable name="name" select="replace($allnames, '([^,&amp;]+)[,&amp;].*', '$1')" />
        <xsl:variable name="nametrim" select="replace($name, ' +$', '')" />
        <xsl:choose>
            <xsl:when test="$tolower = 'true'"><xsl:value-of select="lower-case($nametrim)" /></xsl:when>
            <xsl:otherwise><xsl:value-of select="$nametrim" /></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="suppurl">
        <xsl:param name="suppstr" />
        <xsl:variable name="label" select="substring-before($suppstr, ': http')" />
        <xsl:variable name="url" select="replace($suppstr, '.*: http', 'http')" />
        <xsl:value-of select="$url"/>
    </xsl:template>
    <xsl:template name="suppurllabel">
        <xsl:param name="suppstr" />
        <xsl:variable name="label" select="substring-before($suppstr, ': http')" />
        <xsl:variable name="url" select="replace($suppstr, '.*: http', 'http')" />
        <xsl:value-of select="$label"/>
    </xsl:template>
    
    <xsl:template name="firstspacelastcommaaffil">
        <xsl:param name="fullname" />
        <xsl:param name="tolower" />
        <xsl:param name="affiliationSet" />
        <xsl:param name="index" />
        <xsl:variable name="lastname" select="substring-before($fullname, ',')" />
        <xsl:variable name="firstname" select="replace($fullname, '[^,]+,[ ]*', '')" />
        <xsl:variable name="affiliation" select="$affiliationSet[position()=$index]/text()" />
        <xsl:choose>
            <xsl:when test="string-length($affiliation) = 0">
                <xsl:value-of select="$fullname" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat($fullname, ' (', $affiliation, ')' )" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="grantInfo">
        <xsl:param name="agency" />
        <xsl:param name="grantNumSet" />
        <xsl:param name="index" />
        <xsl:variable name="grantNumVal" select="$grantNumSet[position()=$index]/text()" />
        <xsl:choose>
            <xsl:when test="string-length($grantNumVal) = 0">
                <xsl:value-of select="$agency" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat($agency, ' : ', $grantNumVal )" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="lastcommafirst">
        <xsl:param name="last"/>
        <xsl:param name="first"/>
        <xsl:choose>
            <xsl:when test="string-length($last)= 0"><xsl:value-of select="$first"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="concat($last,', ',$first)"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="dataverse" >
        <xsl:param name="libra-id"/>
        <xsl:variable name="dataverse-id" select="$dataverse-map/entry[libra = $libra-id]/dataverse"/>
        <xsl:if test="string-length(string($dataverse-id)) > 0">
            <field name="url_a">
                <xsl:value-of select="concat($dataverse-url, $dataverse-id, '||UVa Dataverse')"/>
            </field>
        </xsl:if>
    </xsl:template>

    <xsl:template name="cleantitle">
        <xsl:param name="title"/>
        <xsl:param name="language" select="''"/>
        <xsl:variable name="title1" select="lower-case($title)" />
        <xsl:variable name="title2" select='replace($title1, "( )?([^-a-z0-9&apos; ])( )?", "$1$3")' />

        <xsl:variable name="replacestr" >
            <xsl:choose>
                <xsl:when test="$language = 'eng' or $language = 'English'">
                    <xsl-text>^[ ]*(the|a|an) </xsl-text>
                </xsl:when>
                <xsl:when test="$language = 'fre' or $language = 'French'">
                    <xsl-text>^[ ]*(la |le |l&apos;|les |une |un |des )</xsl-text>
                </xsl:when>
                <xsl:when test="$language = 'ita' or $language = 'Italian'">
                    <xsl-text>^[ ]*(uno |una |un |un&apos;|lo |gli |il |i |l&apos;|la |le )</xsl-text>
                </xsl:when>
                <xsl:when test="$language = 'spa' or $language = 'Spanish'">
                    <xsl-text>^[ ]*(el|los|las|un|una|unos|unas) </xsl-text>
                </xsl:when>
                <xsl:when test="$language = 'ger' or $language = 'German'">
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
    
    <xsl:template name="publisherinfo">
        <xsl:choose>
            <xsl:when test="arr[@name='has_model_s']/str = 'info:fedora/afmodel:HydrangeaDataset'" >
                <xsl:value-of select="concat('Date Files/ Data Package Created : ', arr[@name='origin_info_date_created_t']/str)"/>
            </xsl:when>
            <xsl:when test="arr[@name='has_model_s']/str = 'info:fedora/afmodel:HydrangeaBook'" >
                <xsl:call-template name="lastcommafirst">
                    <xsl:with-param name="last" select="arr[@name='origin_info_publisher_t']/str"/>
                    <xsl:with-param name="first" select="int[@name='year_i']"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="arr[@name='has_model_s']/str = 'info:fedora/afmodel:HydrangeaBookPart'" >
                <xsl:value-of select="concat('Chapter in : ', arr[@name='book_0_title_info_0_main_title_t']/str, ', ', arr[@name='mods_book_origin_info_publisher_t']/str, ', ', int[@name='year_i'])"/>
            </xsl:when>
            <xsl:when test="arr[@name='has_model_s']/str = 'info:fedora/afmodel:HydrangeaConferencePaper'">
                <xsl:value-of select="arr[@name='conference_paper_name_conference_name_t']/str"/><xsl:text>, </xsl:text><xsl:value-of select="int[@name='year_i']" />
            </xsl:when>
            <xsl:when test="arr[@name='has_model_s']/str = 'info:fedora/afmodel:HydrangeaArticle'">
                <xsl:call-template name="lastcommafirst">
                    <xsl:with-param name="last" select="arr[@name='journal_origin_info_publisher_t']/str"/>
                    <xsl:with-param name="first" select="int[@name='year_i']"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="arr[@name='has_model_s']/str = 'info:fedora/afmodel:HydrangeaArticlePreprint'">
                <xsl:call-template name="lastcommafirst">
                    <xsl:with-param name="last" select="arr[@name='journal_origin_info_publisher_t']/str"/>
                    <xsl:with-param name="first" select="int[@name='year_i']"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="arr[@name='has_model_s']/str = 'info:fedora/afmodel:HydrangeaDoctoralDissertation'">
                <xsl:value-of select="arr[@name='extension_0_degree_t']/str"/><xsl:text>, </xsl:text><xsl:value-of select="int[@name='year_i']" />
            </xsl:when>
            <xsl:when test="arr[@name='has_model_s']/str = 'info:fedora/afmodel:HydrangeaMastersThesis'">
                <xsl:value-of select="arr[@name='extension_0_degree_t']/str"/><xsl:text>, </xsl:text><xsl:value-of select="int[@name='year_i']" />
            </xsl:when>
            <xsl:when test="arr[@name='has_model_s']/str = 'info:fedora/afmodel:HydrangeaFourthYearThesis'">
                <xsl:value-of select="arr[@name='extension_0_degree_t']/str"/><xsl:text>, </xsl:text><xsl:value-of select="int[@name='year_i']" />
            </xsl:when>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
