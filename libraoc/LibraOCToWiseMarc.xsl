<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:my="http://example.com/my-functions"
    exclude-result-prefixes="my">
    
    <xsl:output omit-xml-declaration="yes" indent="yes"/>
    <xsl:strip-space elements="*"/>
 
    <!-- Define a mapping for month names to month numbers -->
    <xsl:variable name="month-map">
        <month name="January" number="01"/>
        <month name="February" number="02"/>
        <month name="March" number="03"/>
        <month name="April" number="04"/>
        <month name="May" number="05"/>
        <month name="June" number="06"/>
        <month name="July" number="07"/>
        <month name="August" number="08"/>
        <month name="September" number="09"/>
        <month name="October" number="10"/>
        <month name="November" number="11"/>
        <month name="December" number="12"/>
    </xsl:variable>
    
        
    
    
    <!-- Match and copy only the doc elements that meet the conditions -->
    <xsl:template match="response">
        <marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim">
            <xsl:apply-templates select="node()" />
        </marc:collection>
    </xsl:template>
    
    <xsl:template match="lst"/>
    
    <xsl:template match="result">
        <xsl:apply-templates select="node()" />
    </xsl:template>
    
    <!-- Match and copy only the doc elements that meet the conditions -->
    <xsl:template match="doc[arr[@name='publisher_tesim'][str='University of Virginia, College at Wise']]">
        <xsl:call-template name="process-doc">
            <xsl:with-param name="doc" select="." />
        </xsl:call-template>
    </xsl:template>
    
    <!-- Match and skip all other doc elements -->
    <xsl:template match="doc"/>
    
    <!-- Define a local function to flip name to last , first form -->
    <xsl:function name="my:lastcommafirst" as="xs:string*">
        <xsl:param name="inputString" as="xs:string"/>
        <xsl:variable name="name" >
            <xsl:choose>
                <xsl:when test="matches($inputString, 'Dr. |Prof. ')">
                    <xsl:value-of select="substring-after($inputString, '. ')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$inputString"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="last" select="substring-before($name, ' ')"/>
        <xsl:variable name="first" select="substring-after($name, ' ')"/>
        <xsl:value-of select="concat($last, ', ', $first)"/>
    </xsl:function>
    
    <!-- Define a local function to extract interviewers' names -->
    <xsl:function name="my:extract-interviewers" as="xs:string*">
        <xsl:param name="inputString" as="xs:string"/>
        
        <!-- Check for singular and plural forms -->
        <xsl:variable name="interviewersString1" >
            <xsl:choose>
                <xsl:when test="contains($inputString, 'interviewers were ')">
                    <!-- Plural form -->
                    <xsl:value-of select="substring-before(substring-after($inputString, 'interviewers were '), '.')"/>
                </xsl:when>
                <xsl:when test="contains($inputString, 'interviewer was ')">
                    <!-- Singular form -->
                    <xsl:value-of select="substring-before(substring-after($inputString, 'interviewer was '), '.')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="interviewersString" >
            <xsl:choose>
                <xsl:when test="contains($interviewersString1, ' and the ')">
                    <xsl:value-of select="substring-before($interviewersString1, ' and the ')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$interviewersString1"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:sequence select="tokenize($interviewersString, ' and |, ')"/>
    </xsl:function>
    
    <!-- Define a local function to extract videographers' names -->
    <xsl:function name="my:extract-videographers" as="xs:string*">
        <xsl:param name="inputString" as="xs:string"/>
        
        <!-- Check for singular and plural forms -->
        <xsl:variable name="videographersString1" >
            <xsl:choose>
                <xsl:when test="contains($inputString, 'videographers were ')">
                    <!-- Plural form -->
                    <xsl:value-of select="substring-before(substring-after($inputString, 'the videographers were '), '.')"/>
                </xsl:when>
                <xsl:when test="contains($inputString, 'videographer was ')">
                    <!-- Singular form -->
                    <xsl:value-of select="substring-before(substring-after($inputString, 'the videographer was '), '.')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="videographersString" >
            <xsl:choose>
                <xsl:when test="contains($videographersString1, ' and the ')">
                    <xsl:value-of select="substring-before($videographersString1, ' and the ')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$videographersString1"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:sequence select="tokenize($videographersString, ' and |, ')"/>
    </xsl:function>
    
    <xsl:template name="formatDuration">
        <xsl:param name="number"/>
        <xsl:param name="label"/>
        <xsl:choose>
            <xsl:when test="$number = 0">
                <xsl-value-of select="''"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat($number, ' ', $label)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="lastcommafirstfromJson">
        <xsl:param name="json"/>
        <xsl:variable name="first" select="substring-before(substring-after($json, 'first_name&quot;:&quot;'), '&quot;')"/> 
        <xsl:variable name="last" select="substring-before(substring-after($json, 'last_name&quot;:&quot;'), '&quot;')"/>
        <xsl:value-of select="concat($last, ', ', $first)"/>
    </xsl:template>
    
    <xsl:template name="parseDate" >
        <xsl:param name="dateString"/>
        <!-- Extract parts of the date string -->
        <xsl:variable name="monthName" select="substring-before($dateString, ' ')" />
        <xsl:variable name="day" select="xs:numeric(substring-before(substring-after($dateString, ' '), ','))" />
        <xsl:variable name="year" select="substring-after($dateString, ', ')" />
        
        <!-- Convert month name to number -->
        <xsl:variable name="monthNumber" select="$month-map/month[@name = $monthName]/@number" />
        
        <!-- Construct xs:date string -->
        <xsl:value-of select="xs:date(concat($year, '-', $monthNumber, '-', format-number($day, '00')))" />
    </xsl:template>
    
    <xsl:template name="outputnamesubfields">
        <xsl:param name="name"/>
        <xsl:variable name="dr" select="replace($name, '(Dr\.|Prof\.)?.+', '$1')"/>
        <xsl:variable name="rest" select="replace($name, '(Dr\. |Prof\. )?(.+)', '$2')"/>
        <xsl:variable name="last" select="replace($rest, '([^ ]* )*([-A-Za-z.]+)$', '$2')"/>
        <xsl:variable name="firstandnick" select="replace(replace($rest, '((([^ ]*) )*)([-A-Za-z.]+)$', '$1'), '&quot;', '%')"/>
        <xsl:variable name="nickname" select="replace(replace($firstandnick, '^([^%]+)(%([-A-Za-z]+)%)?', '$3'), ' +$', '')"/>
        <xsl:variable name="first" select="replace(replace($firstandnick, '([^%]+)(%([-A-Za-z]+)%)?', '$1'), ' +$', '')"/>
        
        <xsl:variable name="lastfirst" >
            <xsl:choose>
                <xsl:when test="$first != ''">
                    <xsl:value-of select="concat($last, ', ', $first)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$last"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <subfield code="a"><xsl:value-of select="$lastfirst"/></subfield>
        <xsl:if test="$dr != ''">
            <subfield code='c'><xsl:value-of select="$dr"/></subfield>
        </xsl:if>
        <xsl:if test="$nickname != ''">
            <subfield code='q'><xsl:value-of select="$nickname"/></subfield>
        </xsl:if>
        
    </xsl:template>
    
    <xsl:template name="process-doc">
        <xsl:param name="doc"></xsl:param>
        <xsl:variable name="id" select="str[@name='id']"/>
        <xsl:variable name="description" select="replace(arr[@name='description_tesim']/str/text(), '\s+$', '')"/>
        <!-- Extract the videographers and interviewers -->
        <xsl:variable name="videographersSequence" select="my:extract-videographers($description)"/>
        <xsl:variable name="interviewersSequence" select="my:extract-interviewers($description)"/>
               
        <xsl:variable name="title_raw" select="arr[@name='title_tesim']/str"/>
        <xsl:variable name="title_short" select="substring-before($title_raw, ',')"/>
        <xsl:variable name="formattedDateTime" select="format-dateTime(current-dateTime(), '[Y0001][M01][D01][H01][m01][s01].1')"/>
        <!--   <xsl:variable name="formattedDateTime" >
            <xsl:call-template name="format-dateTime">
                <xsl:with-param name="dateTime" select="current-dateTime()" />
            </xsl:call-template>
        </xsl:variable>  -->
        <xsl:variable name="videoUrl" select="substring-after(arr[@name='related_url_tesim']/str, 'here: ')"/>
        <xsl:variable name="videoLabel" select="substring-before(arr[@name='related_url_tesim']/str, ' http')"/>
        <xsl:variable name="videoData" select="unparsed-text($videoUrl)"/>
        <xsl:variable name="duration" select="substring-before(substring-after($videoData,'&quot;duration&quot;:'), ',')"/>
        <xsl:variable name="durationHours" select="floor(xs:numeric($duration) div 3600)"/>
        <xsl:variable name="durationMinutes" select="floor(xs:numeric($duration) div 60)"/>
        <xsl:variable name="durationSeconds" select="floor(xs:numeric($duration) mod 60)"/>
        <xsl:variable name="durationHoursStr" >
            <xsl:call-template name="formatDuration">
                <xsl:with-param name="number" select="$durationHours" />
                <xsl:with-param name="label" select="'hrs '" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="durationMinutesStr" >
            <xsl:call-template name="formatDuration">
                <xsl:with-param name="number" select="$durationMinutes" />
                <xsl:with-param name="label" select="'min '" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="durationSecondsStr" >
            <xsl:call-template name="formatDuration">
                <xsl:with-param name="number" select="$durationSeconds" />
                <xsl:with-param name="label" select="'sec '" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="parsedDate" >
            <xsl:call-template name="parseDate">
                <xsl:with-param name="dateString" select="arr[@name='published_date_tesim']/str" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="rawPublishedDate" select="format-date($parsedDate, '[Y0001][M01][D01]')"/>
        <xsl:variable name="formattedPublishedDate" select="format-date($parsedDate, '[Y0001]-[M01]-[D01]')"/>
        <xsl:variable name="format2PublishedDate" select="format-date($parsedDate, '[Y0001] [MNn] [D1]')"/>
        <xsl:variable name="runtimeRounded" select="format-number(ceiling(xs:numeric($duration) div 60), '000')"/>
        <record>
            <leader><xsl:text>02170cgm a2200493 a 4500</xsl:text></leader>
            <controlfield tag="001"><xsl:value-of select="$id"/></controlfield>
            <controlfield tag="003"><xsl:value-of select="'ViU-LibraOC'"/></controlfield>
            <controlfield tag="005"><xsl:value-of select="$formattedDateTime"/></controlfield>
            <controlfield tag="006"><xsl:text>m---  o  c        </xsl:text></controlfield>
            <controlfield tag="007"><xsl:text>vz czazuu</xsl:text></controlfield>
            <controlfield tag="007"><xsl:text>cr cna|||uuuuu</xsl:text></controlfield>
            <controlfield tag="008"><xsl:value-of select="concat('240513e', $rawPublishedDate, 'vau', $runtimeRounded, '        o   vleng d ')"/></controlfield>
            <datafield tag="028" ind1="4" ind2="0">
                <subfield code="a"><xsl:value-of select="$id"/></subfield>
                <subfield code="b">LibraOpen</subfield>
            </datafield>
            <datafield tag="040" ind1=" " ind2=" ">
                <subfield code="a">ViWisC</subfield>
                <subfield code="c">ViU</subfield>
            </datafield>
            <datafield tag="050" ind1=" " ind2="4">
                <subfield code="a">RA644.c67</subfield>
            </datafield>
            <datafield tag="100" ind1="1" ind2=" ">
                <subfield code="a"><xsl:call-template name="lastcommafirstfromJson"><xsl:with-param name="json" select="arr[@name='authors_tesim']/str[1]"/></xsl:call-template></subfield>
                <subfield code="e">author.</subfield>
                <subfield code="4">aut</subfield>
            </datafield>
            <datafield tag="245" ind1="1" ind2="0">
                <subfield code="a"><xsl:value-of select="$title_raw"/></subfield>
            </datafield>
            <datafield tag="246" ind1="3" ind2="0">
                <subfield code="a"><xsl:value-of select="$title_short"/></subfield>
            </datafield>
            <datafield tag="260" ind1=" " ind2=" ">
                <subfield code="a">Wise, VA. :</subfield>
                <subfield code="b">University of Virginia, College at Wise,</subfield>
                <subfield code="c"><xsl:value-of select="$formattedPublishedDate"/></subfield>
            </datafield>
            <datafield tag="300" ind1=" " ind2=" ">
                <subfield code="a"><xsl:value-of select="concat('1 online resource (1 video file ( ', $durationHoursStr, $durationMinutesStr, $durationSecondsStr, 'duration.)) :')"/></subfield>
                <subfield code="b">hd., col.</subfield>
            </datafield>
            <datafield tag="306" ind1=" " ind2=" ">
                <subfield code="a"><xsl:value-of select="concat(format-number($durationHours, '00'),format-number($durationMinutes, '00'), format-number($durationSeconds, '00'))"/></subfield>
            </datafield>
            <datafield tag="344" ind1=" " ind2=" ">
                <subfield code="a">digital</subfield>
                <subfield code="2">rda</subfield>
            </datafield>
            <datafield tag="347" ind1=" " ind2=" ">
                <subfield code="a">video file</subfield>
                <subfield code="2">rda</subfield>
            </datafield>
            <xsl:for-each select="$interviewersSequence">
                <datafield tag="511" ind1="0" ind2=" ">
                    <subfield code="a"><xsl:value-of select="concat(., ', interviewer.')"/></subfield>
                </datafield>
            </xsl:for-each>
            <xsl:for-each select="$videographersSequence">
                <datafield tag="508" ind1=" " ind2=" ">
                    <subfield code="a"><xsl:value-of select="concat('Videographer, ', ., '.')"/></subfield>
                </datafield>
            </xsl:for-each>
            <datafield tag="518" ind1=" " ind2=" ">
                <subfield code="o">Recorded : </subfield>
                <subfield code="p">Wise, Virginia.</subfield>
                <subfield code="d"><xsl:value-of select="$format2PublishedDate"/></subfield>
            </datafield>
            <datafield tag="520" ind1=" " ind2=" ">
                <subfield code="a"><xsl:value-of select="$description"/></subfield>
            </datafield>
            <xsl:if test="arr[@name='rights_display_ssm']/str != ''  and arr[@name='rights_url_ssm']/str != ''">
                <datafield tag="540" ind1=" " ind2=" ">
                    <subfield code="a"><xsl:value-of select="replace(arr[@name='rights_display_ssm']/str, '(.* )[(](.*)[)](.*)', '$1$3')"/></subfield>
                    <subfield code="f"><xsl:value-of select="replace(arr[@name='rights_display_ssm']/str, '(.* )[(](.*)[)](.*)', '$2')"/></subfield>
                    <subfield code="u"><xsl:value-of select="arr[@name='rights_url_ssm']/str"/></subfield>
                </datafield>
            </xsl:if>
            <datafield tag="588" ind1="0" ind2=" ">
                <subfield code="a">Vendor-supplied metadata.</subfield>
            </datafield>
            <datafield tag="600" ind1="1" ind2="0">
                <xsl:call-template name="outputnamesubfields">
                    <xsl:with-param name="name" select="$title_short"/>
                </xsl:call-template>
                <subfield code="v">Interviews.</subfield>
            </datafield>
            <datafield tag="650" ind1=" " ind2="0">
                <subfield code="a">COVID-19 (Disease)</subfield>
                <subfield code="x">Social aspects.</subfield>
            </datafield>
            <datafield tag="650" ind1=" " ind2="7">
                <subfield code="a">COVID-19 (Disease)</subfield>
                <subfield code="x">Social aspects.</subfield>
                <subfield code="2">fast</subfield>
                <subfield code="0">(OCoLC)fst01984649</subfield>
            </datafield>
            <datafield tag="655" ind1=" " ind2="7">
                <subfield code="a">Oral histories.</subfield>
                <subfield code="2">lcgft</subfield>
            </datafield>
            <datafield tag="655" ind1=" " ind2="7">
                <subfield code="a">Internet videos.</subfield>
                <subfield code="2">lcgft</subfield>
            </datafield>
            <datafield tag="655" ind1=" " ind2="7">
                <subfield code="a">Internet videos.</subfield>
                <subfield code="2">fast</subfield>
                <subfield code="0">(OCoLC)fst01750214</subfield>
            </datafield>
            <datafield tag="655" ind1=" " ind2="7">
                <subfield code="a">Interviews.</subfield>
                <subfield code="2">fast</subfield>
                <subfield code="0">(OCoLC)fst01423832</subfield>
            </datafield>
            <datafield tag="655" ind1=" " ind2="7">
                <subfield code="a">Oral histories.</subfield>
                <subfield code="2">fast</subfield>
                <subfield code="0">(OCoLC)fst01726295</subfield>
            </datafield>
            <xsl:for-each select="arr[@name='coontributors_tesim']">
                <datafield tag="700" ind1="1" ind2=" ">
                    <subfield code="a"><xsl:call-template name="lastcommafirstfromJson"><xsl:with-param name="json" select="./str"/></xsl:call-template></subfield>
                    <subfield code="e">contributor.</subfield>
                    <subfield code="4">ctb</subfield>
                </datafield>
            </xsl:for-each>
            <datafield tag="700" ind1="1" ind2=" ">
                <xsl:call-template name="outputnamesubfields">
                    <xsl:with-param name="name" select="$title_short"/>
                </xsl:call-template>
                <subfield code="e">interviewee.</subfield>
                <subfield code="4">ive</subfield>
            </datafield>
            <xsl:for-each select="$interviewersSequence">
                <datafield tag="700" ind1="1" ind2=" ">
                    <subfield code="a"><xsl:value-of select="my:lastcommafirst(.)"/></subfield>
                    <subfield code="e">interviewer.</subfield>
                    <subfield code="4">ivr</subfield>
                </datafield>
            </xsl:for-each>
            <xsl:for-each select="$videographersSequence">
                <datafield tag="700" ind1="1" ind2=" ">
                    <subfield code="a"><xsl:value-of select="my:lastcommafirst(.)"/></subfield>
                    <subfield code="e">videographer.</subfield>
                    <subfield code="4">vdg</subfield>
                </datafield>
            </xsl:for-each>
            <datafield tag="710" ind1="2" ind2=" ">
                <subfield code="a">University of Virginia, College at Wise</subfield>
                <subfield code="e">producer.</subfield>
                <subfield code="4">pro</subfield>
            </datafield>
            <datafield tag="830" ind1=" " ind2="0">
                <subfield code="a">COVID-19 Oral History.</subfield>
            </datafield>
            <datafield tag="856" ind1="4" ind2="0">
                <subfield code="u"><xsl:value-of select="concat('https://', arr[@name='doi_tesim']/str)"/></subfield>
            </datafield>
            <datafield tag="856" ind1="4" ind2="2">
                <subfield code="u"><xsl:value-of select="$videoUrl"/></subfield>
                <subfield code="y"><xsl:value-of select="$videoLabel"/></subfield>
            </datafield>
            <xsl:if test="arr[@name='rights_display_ssm']/str != ''  and arr[@name='rights_url_ssm']/str != ''">
                <datafield tag="856" ind1="4" ind2="2">
                    <subfield code="t"><xsl:value-of select="replace(arr[@name='rights_display_ssm']/str, '(.* )[(](.*)[)](.*)', '$1$3')"/></subfield>
                    <subfield code="e"><xsl:value-of select="replace(arr[@name='rights_display_ssm']/str, '(.* )[(](.*)[)](.*)', '$2')"/></subfield>
                    <subfield code="r"><xsl:value-of select="arr[@name='rights_url_ssm']/str"/></subfield>
                </datafield>
            </xsl:if>
            
        </record>
    </xsl:template>
</xsl:stylesheet>