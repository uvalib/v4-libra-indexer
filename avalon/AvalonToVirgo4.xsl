<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" 
    xmlns:l="http://language.data"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:rm="http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:local="urn:avalon-to-virgo-local-functions" exclude-result-prefixes="l mods rm local xs">
    <xsl:output indent="yes" />
    <xsl:param name="urlbase" select="string('https://avalon-dev.lib.virginia.edu')" />
    <xsl:param name="modsdir" select="string('./data/mods/')" />
    <!-- Guards the director-name fallback (see emitCreditNames, emitCommaCreditNames) against emitting
         unparsed credit-list text as if it were a person's name. Some MODS credits notes list many
         role/name pairs with NO delimiter at all between a role and the name that follows it (e.g.
         "Director, Producer Sam Feder Producer Amy Scholder Producer Paola Mendoza Executive
         Producers..."), so once a role-word is found there is no reliable boundary telling the
         extraction where that one name ends and the next role word begins; naively taking "everything
         after the role word" would capture the entire remaining credit list as one giant "name". A
         candidate is rejected if it still contains one of these role words (a real person's name
         shouldn't) or is implausibly long for a name (both checked at every point a name is emitted). -->
    <!-- "in collaboration" and a leading "the " (e.g. "the Mime Center, Berlin in collaboration with
         Gennadi Bogdanov", from a real "a film by the Mime Center, Berlin in collaboration with..."
         credit) are organization/group-credit markers, not something a person's own name contains; a
         leading "the " in particular is confirmed safe to reject outright here since a credited
         individual's name essentially never starts with it in this context. -->
    <!-- "translat" and "voice-over"/"voiceover" guard against a real credit shape like "Director, English
         translation and voice-over, Dennis Cokely.": a "Role1, Role2, Name" comma-list where Role2 is
         a role word this vocabulary doesn't otherwise recognize (translation/voice-over work, relevant
         for signed-language and foreign-language content in this collection); without it, "English
         translation and voice-over" was wrongly treated as the name, then further split by the "and"
         connector into two nonsense "directors". -->
    <xsl:variable name="implausibleNameMarker"
        select="'(produc|direct|edit|music|camera|writ|executive|assistant|consulting|contributing|coordinator|operator|cinematographer|compos|presenter|narrator|screenplay|actor|actress|in[ ]collaboration|translat|voice[ -]?over)|^the[ ]'"/>
    <xsl:variable name="maxPlausibleNameWords" select="6"/>
    <xsl:variable name="maxPlausibleNameLength" select="60"/>
 
    <!-- Shared vocabulary for the comma-style director credit ("Role(s), Name(s)") in
         emitCommaCreditNames: a bare director word, optionally combined with one other short role via
         &amp;/and (either order), or a short list of common companion roles. Kept as top-level variables
         so local:isRoleWord/local:containsDirectorWord (below) and emitCommaCreditNames all see the same
         definitions. -->
    <!-- "Film"/"video" are allowed as an optional leading qualifier throughout ("film director", "video
         director", "film producer", etc.), since they're just a redundant clarification of MEDIUM
         (director OF THE FILM/VIDEO, not a different department), unlike "art"/"music"/"casting"/etc.
         (see local:isDirectorLabel's false-friend check, which draws the same distinction for colon
         labels). The core director term itself accepts "director(s)"/"co-director(s)", "direction", or
         "directing" everywhere (bare, compound, or as the ending of a compound), e.g. both "Direction,
         Name" and "Scenario and direction, Name" are recognized, not just the noun form "director(s)". -->
    <!-- A small set of non-English equivalents for "director(s)"/"direction"/"directing" is included
         directly in the core term, confirmed against real examples: Spanish "direccion"/"direccion"
         (e.g. "direccion y dialogos, X"), Portuguese "direcao"/"direcao" (e.g. "roteiro e direcao, X"),
         French "realisation" (e.g. a bare "realisation, X" credit), German "regie" (e.g. "Buch und
         Regie, X"). This is NOT an attempt at full multi-language support (that's a larger, separate
         undertaking); it only covers the specific non-English patterns real examples have confirmed. -->
    <xsl:variable name="CORE_DIRECTOR_TERM"
        select="'(co-?)?directors?|directions?|directing|direcci[oó]n(es)?|dire[cç][aã]o(ns)?|r[ée]alisation|regie'"/>
    <xsl:variable name="DIRECTOR_WORD" select="concat('^(film |video )?(', $CORE_DIRECTOR_TERM, ')$')"/>
    <!-- "y" (Spanish), "e" (Portuguese), "et" (French), and "und" (German) are all accepted alongside
         "&amp;"/"and" as connectors, e.g. "guionista y director" (Spanish), "roteiro e direcao"
         (Portuguese), "ecrit ... et realise" (French, in the verb-list below), "Buch und Regie" (German).
         Confirmed safe since the connector position always requires surrounding spaces, so none of these
         short words can false-match as a substring of another word. -->
    <!-- The connector requires MANDATORY surrounding spaces ("[ ]+", not "[ ]*"): a short, single-letter
         connector like "y"/"e" can otherwise match as a mid-word substring with zero real space around
         it, e.g. "underwater photography directors" was wrongly matching as a false "compound" (the "y"
         inside "photography" treated as the Spanish "and" connector, with the following " directors"
         satisfying the rest of the pattern): a real, confirmed bug, not just a theoretical risk. Every
         real confirmed example already has a genuine space on both sides of its connector regardless
         ("guionista y director", "Buch und Regie"), so requiring it costs nothing. -->
    <xsl:variable name="DIRECTOR_WORD_COMPOUND"
        select="concat(
            '^(film |video )?(', $CORE_DIRECTOR_TERM, ')([ ]+(&amp;|and|y|e|et|und)[ ]+[a-z][a-z ]{0,30})?$',
            '|^[a-z][a-z ]{0,30}[ ]+(&amp;|and|y|e|et|und)[ ]+(film |video )?(', $CORE_DIRECTOR_TERM, ')$')"/>
    <xsl:variable name="CONTAINS_DIRECTOR_WORD"
        select="concat('(^|[^a-z])(film |video )?(', $CORE_DIRECTOR_TERM, ')([^a-z]|$)')"/>
    <!-- "actor"/"actress" is included here (a valid role word for recognizing a comma-joined role LIST,
         e.g. "film director, screenwriter, actor") despite also being an explicit name-plausibility
         rejection marker elsewhere ($implausibleNameMarker, which guards against "actor" ending up
         inside a NAME candidate); the two checks serve different purposes and don't conflict. -->
    <xsl:variable name="OTHER_ROLE_WORDS"
        select="'^(film )?(executive |co-|associate |assistant )?(produc(er|tion)|writ(er|ing)|edit(or|ing)|compos(er)|cinematographer|narrator|presenter|screenwriter)s?$|^actors?$|^actress(es)?$|^(additional[ ])?(script|screenplay|story|sound([ ]design)?|music(al)?|camera([ ]operator)?|cinematography|production|cast(ing)?|dp)$'"/>
 
    <!-- Is $t (one comma-separated token, already trimmed) a recognized role word for the purposes of
         the comma-style credit? Accepts a bare/compound director form or a short companion role
         directly, OR, since real records write slash-joined compounds like "Director/producer/writer"
         or "Producer/director" in either order, a "/"-joined list where EVERY part is individually
         one of those same recognized words. A trailing "." is stripped first (a token at the end of a
         sentence, e.g. "...; Ken Rockefeller, director.", still a bare "director" word). -->
    <!-- Splits "X and Y" / "X &amp; Y" / "X with Y" into two separate co-director names, but ONLY when X
         (the part before the connector) already has 2+ words on its own, e.g. "G. Kozintsev and L.
         Trauberg" or "Lucien Castaing-Taylor and Véréna Paravel", both clearly two complete names.
         Without that check, "Andrea and Peter Hylands" (a real credit, "Director: Andrea and Peter
         Hylands") would wrongly split into "Andrea" (missing her shared surname) and "Peter Hylands",
         since here "Andrea" is a bare first name borrowing Peter's surname, not a complete name of her
         own. "with" is included alongside "and"/"&amp;" per a real confirmed example, "Directed by Beth
         Stephens with Annie Sprinkle", which splits into two directors the same way. The split is also
         skipped entirely when the WHOLE unsplit text already matches $implausibleNameMarker, e.g.
         "Berlin in collaboration with Gennadi Bogdanov" (from a real, confirmed-should-be-excluded
         credit, "a film by the Mime Center, Berlin in collaboration with Gennadi Bogdanov"): without
         this, splitting on "with" would separate the organization half (correctly rejected on its own
         for containing "in collaboration") from the name half ("Gennadi Bogdanov"), letting the name
         half slip through a marker check it was supposed to fail as part of the whole phrase. Only
         handles the simple two-part case; three or more "and"/"&amp;"/"with"-joined parts, or a
         connector with nothing recognizable on one side, are left unsplit as a safe default rather than
         guessed at. -->
    <!-- Does $segment genuinely indicate directing before whichever of "by"/"por"/"par" (English/
         Spanish-Portuguese/French) appears first in it? Generalizes the old plain "contains 'direct'"
         check so a verb-list made of recognized foreign directing verbs (e.g. "dirigida por X", "ecrit,
         produit et realise par X") can satisfy it too, not just the English word "direct". Finds the
         earliest of the three prepositions (naive substring search, so e.g. "by" embedded inside an
         unrelated word is possible here, same accepted limitation as elsewhere in this fallback, since
         this is a disambiguation gate, not the actual name extraction, which has its own, stricter,
         boundary-aware matching), then checks only the text before that position for any of the
         directing-indicator roots: "direct" (English), "dirig" (Spanish/Portuguese "dirigido/a"),
         "direcc"/"direç"/"direc" (Spanish/Portuguese "direccion"/"direcao"), "realis" (French
         "realise"/"realisation", matched after normalizing the accented "e"), "regie" (German),
         "diret" (Italian "diretto"/"diretta"). -->
    <xsl:function name="local:mentionsDirectingBeforePreposition" as="xs:boolean">
        <xsl:param name="segment" as="xs:string"/>
        <xsl:variable name="segLower" select="lower-case(translate($segment, 'éè', 'ee'))"/>
        <xsl:variable name="byPos" select="if (contains($segLower, 'by')) then string-length(substring-before($segLower, 'by')) else -1"/>
        <xsl:variable name="porPos" select="if (contains($segLower, 'por')) then string-length(substring-before($segLower, 'por')) else -1"/>
        <xsl:variable name="parPos" select="if (contains($segLower, 'par')) then string-length(substring-before($segLower, 'par')) else -1"/>
        <xsl:variable name="daPos" select="if (contains($segLower, 'da')) then string-length(substring-before($segLower, 'da')) else -1"/>
        <xsl:variable name="validPositions" select="($byPos, $porPos, $parPos, $daPos)[. ge 0]"/>
        <xsl:variable name="prefix" select="
            if (exists($validPositions)) then substring($segLower, 1, min($validPositions)) else $segLower"/>
        <xsl:sequence select="
            contains($prefix, 'direct') or contains($prefix, 'dirig') or contains($prefix, 'direcc')
            or contains($prefix, 'direc') or contains($prefix, 'realis') or contains($prefix, 'regie')
            or contains($prefix, 'diret')"/>
    </xsl:function>
 
    <!-- A generational suffix ("Jr.", "Sr.", "II", "III", "IV", "V") is part of the SAME name as
         whatever precedes its comma, not a separate person, e.g. "John L. Jackson, Jr." is one director,
         not two ("John L. Jackson" and "Jr."). Since every comma-split in this fallback otherwise treats
         each comma as separating different people, the comma right before a suffix is protected first
         (swapped for a private-use placeholder character that survives any tokenize(...,',') call
         untouched) and restored afterward on whichever token ends up keeping it. \b isn't available, so
         the suffix's end is approximated the same way as elsewhere in this file: a following comma,
         period, or end of string. -->
    <xsl:function name="local:protectSuffixCommas" as="xs:string">
        <xsl:param name="text" as="xs:string"/>
        <xsl:sequence select="replace($text, ',(\s*(Jr|Sr|II|III|IV|V)\.?)([,.]|$)', '&#xE000;$1$3', 'i')"/>
    </xsl:function>
 
    <xsl:function name="local:restoreSuffixCommas" as="xs:string">
        <xsl:param name="text" as="xs:string"/>
        <xsl:sequence select="replace($text, '&#xE000;', ',')"/>
    </xsl:function>
 
    <xsl:function name="local:splitCoDirectorNames" as="xs:string*">
        <xsl:param name="text" as="xs:string"/>
        <xsl:variable name="parts" select="tokenize(normalize-space($text), '\s+and\s+|\s+&amp;\s+|\s+with\s+', 'i')"/>
        <xsl:sequence select="
            if (count($parts) = 2 and count(tokenize(normalize-space($parts[1]), '\s+')) ge 2
                and not(matches(lower-case($text), $implausibleNameMarker)))
            then $parts
            else $text"/>
    </xsl:function>
 
    <xsl:function name="local:isRoleWord" as="xs:boolean">
        <xsl:param name="t" as="xs:string"/>
        <xsl:variable name="tt" select="lower-case(replace($t, '[.]$', ''))"/>
        <xsl:sequence select="
            matches($tt, $DIRECTOR_WORD) or matches($tt, $DIRECTOR_WORD_COMPOUND) or matches($tt, $OTHER_ROLE_WORDS) or
            (contains($tt, '/') and (every $sub in tokenize($tt, '/') satisfies (matches(normalize-space($sub), $DIRECTOR_WORD) or matches(normalize-space($sub), $OTHER_ROLE_WORDS)))) or
            ((contains($tt, '-') and not(matches($tt, $DIRECTOR_WORD)) and not(matches($tt, $DIRECTOR_WORD_COMPOUND)))
             and (every $sub in tokenize($tt, '-') satisfies (matches(normalize-space($sub), $DIRECTOR_WORD) or matches(normalize-space($sub), $OTHER_ROLE_WORDS))))"/>
    </xsl:function>
 
    <!-- Does $t (as above) actually name directing, even combined with another role or slash-/hyphen-
         joined (e.g. "Directors-writers-producers")? -->
    <xsl:function name="local:containsDirectorWord" as="xs:boolean">
        <xsl:param name="t" as="xs:string"/>
        <xsl:variable name="tt" select="lower-case(replace($t, '[.]$', ''))"/>
        <xsl:sequence select="
            matches($tt, $CONTAINS_DIRECTOR_WORD) or
            (contains($tt, '/') and (some $sub in tokenize($tt, '/') satisfies matches(normalize-space($sub), $DIRECTOR_WORD)))"/>
    </xsl:function>
 
    <!-- Is $label (a colon-label, or one role-phrase pulled out of a "(...)" group) a genuine director
         credit? Accepted whether bare ("Director"), combined with another role ("Script and
         Directing", "Film director" (the word "Film" is explicitly NOT treated as a disqualifying qualifier,
         unlike "Art"/"Music"/etc., since it's just a redundant clarification that this is the director
         OF THE FILM, not a different department), or appearing anywhere in a longer compound label.
         Rejected if it's a qualified non-directing role ("Art Director", "Director of Photography") or
         "director" is used as a possessive ("director's cut"); that last check is called out
         explicitly in DirectorMixin.java as a necessary guard against exactly this kind of false match. -->
    <xsl:function name="local:isDirectorLabel" as="xs:boolean">
        <xsl:param name="label" as="xs:string"/>
        <xsl:variable name="label_lc" select="lower-case($label)"/>
        <xsl:variable name="has_director_word"
            select="matches($label_lc, '(^|[^a-z])(co-?)?directors?([^a-z]|$)') or
                    matches($label_lc, '(^|[^a-z])directing([^a-z]|$)') or
                    matches($label_lc, '(^|[^a-z])direction([^a-z]|$)')"/>
        <xsl:variable name="is_false_friend"
            select="matches($label_lc, '(art|artistic|music(al)?|stage|production|project|photograph(y|ic)|animation|medical|casting|technical|dance|editing|executive|creative|associate|assistant)[ ]+directors?') or
                    matches($label_lc, 'directors?[ ]+of[ ]') or
                    matches($label_lc, '(^|[^a-z])directors?''s?([^a-z]|$)')"/>
        <xsl:sequence select="$has_director_word and not($is_false_friend)"/>
    </xsl:function>
 
    <!-- Is $line, taken ENTIRELY on its own (no colon, no comma, nothing else), a director-indicating
         role label? Used only for the blank-line-delimited block format below: "Label" alone on one
         line, one name per line after it, a blank line ending the block (e.g. "Written and Directed
         by\nGiorgio Angelini\n\nEditor\nDrew Blatman\n\n..."). Requiring no colon/comma keeps this from
         ever matching a complete "Label: Name" or "Label, Name" line; those are handled by the normal
         per-segment dispatch and must never be reinterpreted as "label with the name on a following
         line", which would wrongly treat that line's own name as a label and the line after it as if it
         were another name. Accepts either a bare role word (reusing isDirectorLabel, so "Director"/
         "Direction" match and "Director of Photography"/"Editor" correctly don't), or a verb-list ending
         in "by" with NOTHING after it (e.g. "Written and Directed by", "Produced by"; the latter
         correctly isn't director-related since it has no "direct" root before "by"). -->
    <xsl:function name="local:isBlockDirectorLabel" as="xs:boolean">
        <xsl:param name="line" as="xs:string"/>
        <!-- Deliberately does NOT reuse isDirectorLabel: that function only checks whether a director
             word appears as a SUBSTRING (correct for a colon-label already isolated by substring-before
             (':')), which would wrongly accept a complete "Director Maurice Schwartz" line as "just a
             label" (the substring check is satisfied by "Director" regardless of what follows it on the
             same line). Here the WHOLE line must fully match $DIRECTOR_WORD/$DIRECTOR_WORD_COMPOUND
             (both already anchored ^...$), which requires nothing else to be present at all; so a name
             tacked on with a bare space, as in "Director Maurice Schwartz", correctly fails to match and
             falls through to the ordinary per-segment dispatch instead. -->
        <!-- A trailing colon ("DIRECTOR:") is a common stylistic variant of a bare label and is
             stripped before matching, same as trailing whitespace. -->
        <xsl:variable name="l" select="lower-case(replace(normalize-space($line), '[ \t]*:$', ''))"/>
        <!-- A comma-joined list of role words (not just the &amp;/and-joined compound $DIRECTOR_WORD_COMPOUND
             already handles), e.g. "Director, Producer" as a bare block label with the name(s) on
             following lines, both roles applying to the same name. Capped at 4 roles and every token
             must independently be a recognized role word (not just the first), with at least one
             naming directing, to stay as conservative as the &amp;/and case above. -->
        <xsl:variable name="comma_tokens" select="tokenize($l, ',')[normalize-space(.) != '']"/>
        <xsl:sequence select="
            matches($l, $DIRECTOR_WORD_COMPOUND) or matches($l, $DIRECTOR_WORD)
            or (matches($l, '^(\[?(co-?)?(written|produc(e|ed|ing|er)|direct(ed|ion|ing)?|director|edit(ed|ing|or)?|camera|cinematography|film(ed|ing)?|photograph(ed|ing)?|creat(ed|ing)?|shot|shooting|perform(ed|ing)?|stag(ed|ing)?|narrat(ed|ing)?)\]?[,]?[ ]*(&amp;|and)?[ ]*)+\[?by\]?$')
                and contains(substring-before(concat($l, 'by'), 'by'), 'direct'))
            or (count($comma_tokens) ge 2 and count($comma_tokens) le 4
                and (every $t in $comma_tokens satisfies local:isRoleWord(normalize-space($t)))
                and (some $t in $comma_tokens satisfies local:containsDirectorWord(normalize-space($t))))"/>
    </xsl:function>
 
    <!-- Broader than isBlockDirectorLabel: used only to decide where a stacked "Label\nName\nLabel\nName"
         block (no blank line between credits) should STOP consuming lines as names for the CURRENT
         label, not to decide whether a label itself is director-related. A bare role word ("Producer")
         stops it correctly already via local:isRoleWord, but a verb-list-ending-in-by label that ISN'T
         about directing ("Produced by") did not, since that shape was only recognized by
         isBlockDirectorLabel when "direct" appears before "by", so a block like "Written & Directed
         by\nLIZ SARGENT\nProduced by\nMINOS PAPAS\nExecutive Producers\n..." never stopped at "Produced
         by", wrongly pulling the producer's name in as a second "director" too. This checks the SAME
         verb-list-ending-in-by shape without that directing-specific requirement, since for STOPPING
         purposes any recognizable role-starting line (whatever the role) signals a new credit beginning,
         not just a directing-related one. -->
    <!-- Cuts at a following role sharing the same captured text, in either of two shapes: a "Capitalized
         Label:"/"Capitalized Label," continuation (the original case, e.g. "Director: X. Cinematography:
         Y."), or a bare "word(s) by" continuation with no colon/comma at all (needed once the narrative
         dispatch started picking up verb-list-by-name credits, since those sometimes run two such
         credits together in one segment with no semicolon between them, e.g. "directed by Lisandro
         Alonso. Music by Domingo Cura", or "Directed, photographed and edited by Miguel Coyula. Produced
         by David Leitner."). The "Capitalized Label:"/"Capitalized Label," shape only cuts when the
         captured word is a RECOGNIZED role word (local:isRoleWord), not just any capitalized word
         followed by a colon or comma; without that check, a middle-initial-plus-surname inside a
         comma-joined name LIST, e.g. "a film by Susannah M. Hoffman, Richard Cowan, Paul Aratow", would
         wrongly match: "M." looks exactly like the end of a sentence, and "Hoffman," looks exactly like
         a new capitalized label ending in a comma, so without the role-word check the whole candidate
         got truncated to "Susannah M." The "word(s) by" shape doesn't need this same check: requiring
         the literal word "by" immediately after is already a much more specific, low-false-positive
         marker on its own. \b (word boundary) isn't available in this XPath version, so the "by" shape's
         word-end is approximated with "a space, then by, then a non-letter or end of string" instead,
         which is enough to avoid false-triggering on a name that happens to end in "...by" as part of a
         word (e.g. "P.A. Backer" or "John Crosby" are both left untouched, confirmed by direct testing). -->
    <xsl:function name="local:periodLabelCut" as="xs:string">
        <xsl:param name="text" as="xs:string"/>
        <xsl:variable name="result">
            <xsl:analyze-string select="$text" regex="\.\s+([A-Z][A-Za-z/ ]*)([:,]).*$|\.\s+[a-z][a-z ]*[ ]by([^a-z]|$).*$" flags="si">
                <xsl:matching-substring>
                    <xsl:choose>
                        <xsl:when test="string-length(regex-group(1)) gt 0 and not(local:isRoleWord(normalize-space(regex-group(1))))">
                            <!-- Captured word isn't a recognized role: not a real cut point, keep as-is. -->
                            <xsl:value-of select="."/>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- Valid cut (role-word colon/comma case, or the "by" case, which always
                                 cuts): emit nothing, removing this match and everything after it. -->
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:value-of select="."/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:sequence select="string($result)"/>
    </xsl:function>
 
    <!-- A false-friend role like "DIRECTOR OF PHOTOGRAPHY" can itself be split across two physical
         lines in a blank-line-block note, e.g. "DIRECTOR\nOF PHOTOGRAPHY\nJohn Smith\n\n..."; taken
         alone, "DIRECTOR" matches local:isBlockDirectorLabel as a perfectly good bare label, and since
         "OF PHOTOGRAPHY" doesn't match local:isAnyRoleLabelLine either (so it doesn't stop the name
         consumption), BOTH "OF PHOTOGRAPHY" and the photography credit's real name ("John Smith" here,
         not a director at all) get wrongly swept in as "directors". Scoped narrowly to the bare noun
         forms ("director(s)"/"direction"/"directing", not a compound or verb-list label, which don't
         show this same split-false-friend risk) immediately followed by a line starting with "of ",
         which is specific enough to safely catch "director of photography"/"director of production
         design"/etc. split this way without touching a genuine "DIRECTOR\n<name>" block. -->
    <xsl:function name="local:isSplitFalseFriendLabel" as="xs:boolean">
        <xsl:param name="label" as="xs:string"/>
        <xsl:param name="nextLine" as="xs:string"/>
        <xsl:sequence select="
            matches(lower-case(replace(normalize-space($label), '[ \t]*:$', '')), $DIRECTOR_WORD)
            and matches(normalize-space($nextLine), '^of[ \t]', 'i')"/>
    </xsl:function>
 
    <xsl:function name="local:isAnyRoleLabelLine" as="xs:boolean">
        <xsl:param name="line" as="xs:string"/>
        <xsl:variable name="l" select="lower-case(replace(normalize-space($line), '[ \t]*:$', ''))"/>
        <xsl:sequence select="
            local:isRoleWord($l)
            or matches($l, '^(\[?(co-?)?(written|produc(e|ed|ing|er)|direct(ed|ion|ing)?|director|edit(ed|ing|or)?|camera|cinematography|film(ed|ing)?|photograph(ed|ing)?|creat(ed|ing)?|shot|shooting|perform(ed|ing)?|stag(ed|ing)?|narrat(ed|ing)?)\]?[,]?[ ]*(&amp;|and)?[ ]*)+\[?by\]?$')"/>
    </xsl:function>
 
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz    '"/>
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ,;-:.'"/>
    <xsl:variable name="shadowed_collection_list" select="document('./CollectionShadow.xml')"/>
    <xsl:variable name="shadowed_collection_as_text">
        <xsl:for-each select="$shadowed_collection_list/collection-ids/id">
            <xsl:value-of select="concat(' ', text(), ' ')" />
        </xsl:for-each>
    </xsl:variable>
<!--    <xsl:variable name="lang_lookup">
        <lang>
            <abb>eng</abb>
            <name>English</name>
        </lang>
    </xsl:variable>
-->    
    <xsl:template match="text()" priority="-1"/>
    
    <xsl:template match="result">
        <add>
            <xsl:apply-templates select="*"/>
        </add>
    </xsl:template>
    
    <xsl:template match="doc">
        <!-- MODS file for this record; doc-available() is false if it is missing, empty, or not well-formed XML
             (e.g. Fedora returns a plain-text "tombstone" message for objects that were deleted from Fedora) -->
        <xsl:variable name="mods_uri" select="concat($modsdir, str[@name = 'id']/text(), '_mods.xml')"/>
        <xsl:if test="arr[@name='has_model_ssim']/str = 'MediaObject' and not(doc-available($mods_uri))">
            <xsl:message terminate="no">
                <xsl:value-of select="concat('ERROR: Avalon id ', str[@name = 'id']/text(), ': MODS file ', $mods_uri, ' is missing or is not well-formed XML; record skipped (not added to output)')"/>
            </xsl:message>
        </xsl:if>
        <xsl:if test="arr[@name='has_model_ssim']/str = 'MediaObject' and doc-available($mods_uri)">
            <doc>
              <xsl:variable name="audio" select="arr[@name = 'avalon_resource_type_ssim']/str[lower-case(normalize-space(.)) = 'sound recording']"/>
              <xsl:variable name="video" select="arr[@name = 'avalon_resource_type_ssim']/str[lower-case(normalize-space(.)) = 'moving image']"/>
              <xsl:variable name="avalonId" select="str[@name = 'id']/text()" />
              <xsl:variable name="solrId" select="concat('avalon_', $avalonId)" />
                 
              <field name="id"><xsl:value-of select="$solrId" /></field>
              <field name="url_str_stored">
                  <xsl:value-of select="concat($urlbase, '/media_objects/', $avalonId)"/>
              </field>                  
              <!--             <field name="digital_collection_f_stored">Libra Repository</field>  -->
              
              <!-- Load MODS data from file based on filename built from id.  Invoke data extraction from MODS document -->
              <xsl:variable name="mods_doc" select="document(concat($modsdir, $avalonId, '_mods.xml'))"/>
  
              <xsl:apply-templates select="$mods_doc/node()"/>
 
              <xsl:for-each select="arr[@name='unit_ssim']">
                  <xsl:call-template name="library_facet" >
                      <xsl:with-param name="unit" select="str"/>
                  </xsl:call-template>
              </xsl:for-each>
 
              <field name="circulating_f">true</field>
              <field name="source_f_stored">Avalon</field>
              <field name="source_f_stored">UVA Library Digital Repository</field>
              <field name="data_source_str_stored">avalon</field>
              <!-- Languages named in the MODS (text form), in document order, blanks and duplicates removed -->
              <xsl:variable name="lang_terms"
                  select="$mods_doc/mods:mods/mods:language/mods:languageTerm[@type='text'][normalize-space(.) != ''][not(normalize-space(.) = preceding::mods:languageTerm[@type='text']/normalize-space(.))]"/>
              <!-- First language drives article-stripping in cleantitle; default English if none given -->
              <xsl:variable name="lang_name" select="if (exists($lang_terms)) then normalize-space($lang_terms[1]) else 'English'"/>
              <!-- Flag any <language> that has a code term but no (non-blank) text term -->
              <xsl:for-each select="$mods_doc/mods:mods/mods:language[mods:languageTerm[@type='code']][not(mods:languageTerm[@type='text'][normalize-space(.) != ''])]">
                  <xsl:message terminate="no">
                      <xsl:value-of select="concat('ERROR: Avalon id ', $avalonId, ': MODS language has languageTerm type=code (', string-join(mods:languageTerm[@type='code']/normalize-space(.), ','), ') but no languageTerm type=text; no language_f_stored value emitted for it')"/>
                  </xsl:message>
              </xsl:for-each>
              <xsl:variable name="default_title">
                  <xsl:choose>
                      <xsl:when test="str[@name = 'title_tesi']/text()">
                          <xsl:value-of select="normalize-space(str[@name = 'title_tesi']/text())"/>
                      </xsl:when>
                      <xsl:when test="$audio and not($video)">
                          <xsl:value-of select="'Untitled Sound Recording'"/>
                      </xsl:when>
                      <xsl:otherwise>
                          <xsl:value-of select="'Untitled Video'"/>
                      </xsl:otherwise>
                  </xsl:choose>
              </xsl:variable>    
              <xsl:variable name="cleaned_title" >
                  <xsl:call-template name="cleantitle">
                      <xsl:with-param name="title" select="$default_title"/>
                      <xsl:with-param name="language" select="$lang_name"/>
                  </xsl:call-template>
              </xsl:variable>
                
              <xsl:choose>
                  <xsl:when test="$audio and not($video)">
                      <field name="url_label_str_stored">Listen Online</field>
                      <field name="pool_f">music_recordings</field>
                      <field name="format_f_stored">Sound Recording</field>
                      <field name="work_title3_key_ssort"><xsl:value-of select="translate(lower-case(concat($cleaned_title, '//MusicRecording')), ' ', '_')" /></field>
                      <field name="work_title2_key_ssort"><xsl:value-of select="translate(lower-case(concat($cleaned_title, '/', normalize-space($mods_doc/mods:mods/mods:name[1]/mods:namePart/text()), '/MusicRecording')), ' ', '_')" /></field>
                  </xsl:when>
                  <xsl:when test="$video">
                      <field name="url_label_str_stored">Watch Online</field>
                      <field name="pool_f">video</field>
                      <field name="format_f_stored">Video</field>
                      <field name="work_title3_key_ssort"><xsl:value-of select="translate(lower-case(concat($cleaned_title, '//video')), ' ', '_')" /></field>
                      <field name="work_title2_key_ssort"><xsl:value-of select="translate(lower-case(concat($cleaned_title, '/', normalize-space($mods_doc/mods:mods/mods:name[1]/mods:namePart/text()), '/video')), ' ', '_')" /></field>
                  </xsl:when>
                  <xsl:otherwise>
                      <field name="url_label_str_stored">Access Online</field>
                      <field name="pool_f">catalog</field>
                      <field name="work_title3_key_ssort"><xsl:value-of select="translate(lower-case(concat($cleaned_title, '//video')), ' ', '_')" /></field>
                      <field name="work_title2_key_ssort"><xsl:value-of select="translate(lower-case(concat($cleaned_title, '/', normalize-space($mods_doc/mods:mods/mods:name[1]/mods:namePart/text()), '/video')), ' ', '_')" /></field>
                  </xsl:otherwise>
              </xsl:choose>
              
              <field name="title_tsearch_stored">
                  <xsl:value-of select="$default_title"/>
              </field>
              <field name="full_title_tsearch_stored">
                  <xsl:value-of select="$default_title"/>
              </field>
              <field name="title_ssort_stored">
                  <xsl:value-of select="$cleaned_title"/>
              </field>
 
              <field name="format_f_stored">Online</field>
                <!-- flat_broke_with_children_women_in_the_age_of_welfare_reform//video -->
              <field name="uva_availability_f_stored">Online</field>
              <field name="anon_availability_f_stored">Online</field>
              <field name="record_date_stored">
                  <xsl:value-of select="current-dateTime()"/>
              </field>
  
              <field name="doc_type_f_stored">avalon</field>
              <!--              <field name="source_facet">Libra2 Repository</field> -->
              <xsl:for-each select="arr[@name='collection_ssim']/str">
                  <field name="digital_collection_f_stored"><xsl:value-of select="."/></field>
              </xsl:for-each>
              <field name="data_source_f_stored">avalon</field>
              <!--             <field name="digital_collection_facet">Libra Repository</field>  -->
              <field name="location_f_stored">Internet Materials</field>
              <field name="shadowed_location_f_stored">
                  <xsl:variable name="collection_id" select="arr[@name='isMemberOfCollection_ssim']/str/text()"/>
                  <xsl:choose>
                      <xsl:when test="contains($shadowed_collection_as_text, concat(' ', $collection_id, ' '))" >
                          <xsl:text>HIDDEN</xsl:text>
                      </xsl:when>
                      <xsl:when test="bool[@name='hidden_bsi']/text() = 'true' ">
                          <xsl:text>UNDISCOVERABLE</xsl:text>
                      </xsl:when>
                      <xsl:when test="str[@name='avalon_publisher_ssi']/text() != ''">
                          <xsl:text>VISIBLE</xsl:text>
                      </xsl:when>
                      <xsl:otherwise>
                          <xsl:text>HIDDEN</xsl:text>
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
 
              <!-- Some records give the director only as a line of text buried in the MODS file's own
                   <note type="creation/production credits">, <note type="statement of responsibility">,
                   or <note type="general"> rather than as a proper mods:name with role code "drt". All
                   three were checked directly against real examples before being included.
                   <note type="general"> was INITIALLY given only the narrowest, most structurally-
                   anchored pattern (the blank-line block), on the theory that it's a far more
                   heterogeneous catch-all than the other two (which are credits-adjacent by convention or
                   in practice) and so a greater false-positive risk for the broader per-segment dispatch.
                   That theory didn't hold up: a thorough manual, file-by-file review of real "general"
                   notes (tagging every name that should and shouldn't be caught) turned up well over a
                   dozen genuine directors missed by the narrow policy: comma-style, colon-style, and
                   slash-joined-compound credits ("director, X", "Director &amp; Editor: X",
                   "Director/producer, X") sitting in "general" notes exactly as they do in the other two
                   note types, while every genuinely non-director "general" note the reviewer looked at
                   (biographical notes about unrelated people, DVD special-features blurbs, a mention of a
                   different language version's director) was correctly left untagged, meaning the
                   existing patterns' own plausibility/false-friend guards were already doing their job
                   there too. So the policy was reversed: <note type="general"> now gets the exact same
                   full per-segment dispatch as the other two note types, below. Only look for this
                   fallback when the MODS doesn't already supply a proper director name, so a record with
                   both doesn't get the name twice. This reads the note(s) directly from the per-record
                   MODS file ($mods_doc), not from any flattened copy in the Solr dump.
 
                   A corpus-wide scan (scan_director_patterns.py) found the credits note uses several
                   distinct conventions across records, not just one. Before anything else, the note is
                   split into blocks on a BLANK line (two or more consecutive newlines), because one real
                   convention puts a role label ALONE on its own line, with one name per line below it,
                   and a blank line ending the block, e.g. "Written and Directed by\nGiorgio Angelini\n
                   \nEditor\nDrew Blatman\n\nProduced by\nGiorgio Angelini\nMaggie Burns\n\n...". A block
                   whose first line matches that shape (see local:isBlockDirectorLabel) has every
                   subsequent line in the block pulled directly as a name; this is the only place a
                   credit is read without a label and its name(s) sharing one line or semicolon-segment,
                   and it's only reached when the first line, taken utterly alone (no colon, no comma),
                   is nothing but a director-indicating role label, which keeps it from ever firing on an
                   ordinary single-line "Label: Name" or "Label, Name" credit that merely happens to span
                   a multi-line block alongside others.
 
                   Every other block (including the common case of the whole note being just one block,
                   when it has no blank lines in it at all) is handled by emitCreditNamesFromBlock: real
                   newlines and semicolons both separate one role/name group from the next within a block
                   (sometimes a note uses one, sometimes the other, sometimes a single very long
                   semicolon-separated line), so both are normalized to the same delimiter first, then
                   each resulting segment is classified and handled by one of five templates, tried in
                   this order:
 
                   1. emitNarrativeCreditNames: "a film by <name>", or a list of one or more verbs
                      (directed/produced/written/edited/filmed/etc., in any order, "directed" needn't be
                      adjacent to "by") joined by commas/"&amp;"/"and", ending in "by <name>", e.g.
                      "Directed by Donna Read", "written and directed by Madeleine Hunt-Ehrlich",
                      "produced, written and directed by X", "director, camera, and editing by X", or
                      "a film by Sekiya Dorsett". A verb-phrase form distinct from the other two since
                      there's no colon or comma between the label and the name.
 
                   2. emitColonCreditNames: "<label>: <name(s)>", where <label> is accepted if it
                      contains "director(s)", "co-director(s)", "directing", or "direction" as a whole
                      word; whether alone ("Director:"), paired with another role ("Script and
                      Directing:"), or repeated bilingually ("Director / Director:", e.g. Spanish-
                      language credits using the same word twice); and rejected if that word is
                      preceded by a qualifier like "art"/"music"/"casting"/etc. or followed by "of ..."
                      (so "Director of Photography:", "Artistic Director:", and similar non-director
                      roles stay excluded). Because the colon unambiguously separates label from name,
                      this check can safely accept an arbitrarily long compound label; there's no risk
                      of misreading which comma-separated word is a name.
 
                   3. emitCommaCreditNames: "<role(s)>, <name(s)>" with NO colon at all (the classic MARC
                      statement-of-responsibility convention, e.g. "Director, Gerry Pomeroy" or
                      "Producer, director, cinematographer, Mai Iskander"), or the reversed "<name>,
                      <role(s)>" (e.g. "Yuval Sharon, Director"). Unlike the colon case, a comma is used
                      for BOTH separating multiple roles from each other AND separating the role list
                      from the name(s), so which comma-separated token is "the name" is genuinely
                      ambiguous without knowing the specific role words involved. To stay safe, this
                      checks each leading token against a short, deliberately incomplete list of common
                      companion roles (producer, writer, editor, composer, cinematographer, and a few
                      others; see $OTHER_ROLE_WORDS below) and only extracts names once it finds a
                      point where the recognized-role-word run ends and at least one of those leading
                      words was a director word; everything after that point is taken as the name(s).
                      A segment with an unrecognized leading role word (e.g. one not in that short list)
                      is left alone rather than guessed at, so an incomplete role vocabulary causes
                      missed credits, not wrong ones.
 
                   4. emitParentheticalCreditNames: "<name> (<role>)(<role>)..." or "<name> (<role>,
                      <role>, ...)" (e.g. "CJ Hunt (Film director)(Screenwriter)", "Eli Steele (Writer,
                      Editor, Director, Producer)"). Every "(...)" group is pulled out and comma-split,
                      each resulting role phrase checked with the same local:isDirectorLabel used for
                      colon labels (so "Film director" counts; "Director of Photography" doesn't); the
                      name is everything before the first "(". Checked before the colonless and comma
                      cases below since a name's trailing comma before "(...)" would otherwise look like
                      a (failing) comma-style credit.
 
                   5. emitColonlessCreditNames: "(Co-)?Director <name>" with no colon, "by", or comma at
                      all (e.g. "Director Maurice Schwartz", "Director Mengzhu Xue"); only tried when
                      nothing else matched and the segment has no comma, so it can't misfire on anything
                      the comma case would otherwise handle. Requires a capital letter immediately after
                      "Director ", and cuts at the first " / " for records that chain several unlabeled
                      role/name pairs that way (e.g. "Director X / Dir. of Photography Y / Sound Z").
 
                   Deliberately NOT handled, since no real example found gave a safe way to extract a
                   name: a bare "Director" line with no name on it at all; a "Name (...co-directors)"
                   parenthetical where the tag's scope over a preceding list of several names is
                   ambiguous (distinct from the clean one-name-then-parens case above); and a record
                   where the SAME credits note has one older, colon-less, comma-less "Director Name"-
                   style block sitting alongside a separate, properly labeled modern credit for a
                   different person; matching the older block risks preferring the wrong one of two
                   plausible directors, or in the one real case checked, a DIFFERENT name close by that
                   actually belongs to someone else entirely. These are left for manual review.
 
                   Each of the five templates ends by calling emitCreditNames on whatever text it
                   decided was "the name(s) portion", which applies two further cleanup passes for
                   records where several roles still share that text: a leading cut at the first "|"
                   (e.g. "Director: X | Producer: Y | ..."), then a cut at the first ". <Capitalized
                   word>:" (e.g. "Director: X. Cinematography: Y."), before splitting on remaining commas.
                   distinct-values() drops a duplicate if the same name is produced more than once. -->
              <xsl:variable name="has_mods_director" select="exists($mods_doc/mods:mods/mods:name[mods:role/mods:roleTerm[@type='code'] = 'drt'])"/>
              <xsl:if test="not($has_mods_director)">
                  <xsl:variable name="director_names_from_notes">
                      <xsl:for-each select="$mods_doc/mods:mods/mods:note[@type='creation/production credits' or @type='statement of responsibility' or @type='general']">
                          <!-- Some MODS files encode Windows-style line breaks as an explicit &#xD; entity
                               (a real, literal carriage return, deliberately not normalized away by the
                               XML parser) followed by an ordinary newline. XPath's regex "." does not
                               match that literal CR, but "$" in multiline mode anchors only right before
                               the LF, one character further along, so a line ending in \r\n never
                               satisfies a "$"-anchored match at all. Strip CR first. -->
                          <xsl:variable name="note_text_no_cr" select="translate(., '&#13;', '')"/>
                          <!-- Split into blocks on a BLANK line (two or more consecutive newlines) before
                               anything else, since some records use a distinct convention across
                               blank-line-delimited blocks: a role label alone on its own line, then one
                               name per line below it, e.g. "Written and Directed by\nGiorgio Angelini\n
                               \nEditor\nDrew Blatman\n\n...". A block matching that shape (see
                               local:isBlockDirectorLabel) is handled directly, pulling every subsequent
                               line in the block as a name; every other block (including the common case
                               of one block containing the whole note, when there are no blank lines in
                               it at all) falls through to emitCreditNamesFromBlock, the ordinary
                               semicolon/newline-normalized per-segment dispatch this fallback always
                               used, just factored into its own template so both paths can share it. -->
                          <xsl:for-each select="tokenize($note_text_no_cr, '\n[ \t]*\n+')">
                              <xsl:variable name="block" select="."/>
                              <xsl:variable name="block_lines" select="tokenize($block, '\n')[normalize-space(.) != '']"/>
                              <xsl:choose>
                                  <xsl:when test="count($block_lines) ge 2 and local:isBlockDirectorLabel($block_lines[1])
                                                  and not(local:isSplitFalseFriendLabel($block_lines[1], $block_lines[2]))">
                                      <xsl:variable name="rest" select="subsequence($block_lines, 2)"/>
                                      <!-- Some records stack several "Label:\nName" credits back-to-back
                                           with NO blank line between them at all (unlike the convention
                                           this block shape was built for, which always has one), e.g.
                                           "DIRECTOR:\nAiwan Obinyan\nEXECUTIVE PRODUCER:\nDr.Evaristus
                                           Obinyan" as one single unbroken block. Without a stopping
                                           point, every line after the first label, including later,
                                           unrelated labels and their names, was taken as a name for
                                           THIS label. Stop at the first subsequent line that is itself
                                           ANY recognizable role-starting label (bare role word, or a
                                           verb-list-ending-in-by label whatever the role, e.g. "Produced
                                           by", not just a director-specific one; see
                                           local:isAnyRoleLabelLine), which signals a new credit starting
                                           there. A real example this specifically fixes: "Written &amp;
                                           Directed by\nLIZ SARGENT\nProduced by\nMINOS PAPAS\nExecutive
                                           Producers\n..." was previously pulling MINOS PAPAS (the
                                           producer) in as a second "director" too, since "Produced by"
                                           wasn't recognized as a stopping point (only "Executive
                                           Producers", a bare noun phrase, further down was). -->
                                      <xsl:variable name="stop_at" select="
                                          for $i in (1 to count($rest))
                                          return if (local:isAnyRoleLabelLine($rest[$i])) then $i else ()"/>
                                      <xsl:variable name="names_lines" select="
                                          if (exists($stop_at)) then subsequence($rest, 1, min($stop_at) - 1) else $rest"/>
                                      <xsl:for-each select="$names_lines">
                                          <xsl:variable name="candidate" select="replace(replace(normalize-space(.), '^(and|&amp;)[ ]+', '', 'i'), '[.]$', '')"/>
                                          <xsl:if test="$candidate != ''
                                                        and not(matches(lower-case($candidate), $implausibleNameMarker))
                                                        and string-length($candidate) le $maxPlausibleNameLength
                                                        and count(tokenize($candidate, '\s+')) le $maxPlausibleNameWords">
                                              <name><xsl:value-of select="$candidate"/></name>
                                          </xsl:if>
                                      </xsl:for-each>
                                  </xsl:when>
                                  <xsl:otherwise>
                                      <xsl:call-template name="emitCreditNamesFromBlock">
                                          <xsl:with-param name="block_text" select="$block"/>
                                      </xsl:call-template>
                                  </xsl:otherwise>
                              </xsl:choose>
                          </xsl:for-each>
                      </xsl:for-each>
                  </xsl:variable>
                  <xsl:for-each select="distinct-values($director_names_from_notes/name/text())">
                      <field name="author_director_tsearch_stored"><xsl:value-of select="."/></field>
                  </xsl:for-each>
              </xsl:if>
              
              <xsl:if test="str[@name='summary_ssi']/text() != ''">
                  <field name="abstract_tsearch_stored"><xsl:value-of select="str[@name='summary_ssi']/text()" /></field>
              </xsl:if>
              <field name="date_indexed_f_stored"><xsl:call-template name="formatDateTime">
                  <xsl:with-param name="dateTime"><xsl:value-of select='current-dateTime()'/></xsl:with-param>
                  </xsl:call-template>
              </field>
              <xsl:if test="arr[@name='section_id_ssim']/str">
                  <field name="thumbnail_url_stored"><xsl:value-of select="concat($urlbase, '/master_files/', arr[@name='section_id_ssim']/str[1]/text(), '/thumbnail')"/></field>
                  <xsl:for-each select="arr[@name='section_id_ssim']/str">
                      <field name="identifier_e_stored"><xsl:value-of select="./text()"/></field>
                  </xsl:for-each>
              </xsl:if>
              <xsl:choose>
                  <xsl:when test="exists($lang_terms)">
                      <xsl:for-each select="$lang_terms">
                          <field name="language_f_stored"><xsl:value-of select="normalize-space(.)"/></field>
                      </xsl:for-each>
                  </xsl:when>
                  <xsl:when test="not($mods_doc/mods:mods/mods:language)">
                      <!-- no language given at all: keep historical default -->
                      <field name="language_f_stored">English</field>
                  </xsl:when>
              </xsl:choose>
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
    
    <xsl:template name="library_facet" >
        <xsl:param name="unit" />
        <xsl:variable name='library_facet'>
            <!--
              - OLE
  - Albert and Shirley Small Special Collections Library
  - Robertson Media Center
  - University of Virginia School of Architecture
  - Music Library
  - Women, Gender, and Sexuality Program
  - University of Virginia Department of Spanish, Italian, and Portuguese
  - Claude Moore Health Sciences Library
  - Scholars' Lab
  - University of Virginia Library
  - Language Commons
  - Research & Learning Services
  - Arthur J. Morris Law Library
  - The Fralin Museum of Art
            -->
            <xsl:choose>
                <xsl:when test="$unit='Albert and Shirley Small Special Collections Library'">
                    <xsl:value-of select="'Special Collections'"/>
                </xsl:when>
                <xsl:when test="$unit='Robertson Media Center'">
                    <xsl:value-of select="'Clemons'"/>
                </xsl:when>
                <xsl:when test="$unit='Music Library'">
                    <xsl:value-of select="'Music'"/>
                </xsl:when>
                <xsl:when test="$unit='Claude Moore Health Sciences Library'">
                    <xsl:value-of select="'Health Sciences'"/>
                </xsl:when>
                <xsl:when test="$unit='Arthur J. Morris Law Library'">
                    <xsl:value-of select="'Law'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="$library_facet!=''">
            <field name="library_f_stored" >
                <xsl:value-of select="$library_facet" />
            </field>
        </xsl:if>
    </xsl:template>
 
    <xsl:template name="runtime_fmt">
        <xsl:param name="millis"/>
        <xsl:variable name="seconds" select="floor($millis div 1000)"/>
        <xsl:if test="floor($seconds div 3600) > 0 ">
            <xsl:value-of select="format-number(floor($seconds div 3600), '00:')" />
        </xsl:if>
        <xsl:value-of select="format-number(floor($seconds div 60) mod 60, '00')"/>
        <xsl:value-of select="format-number($seconds mod 60, ':00')"/>
    </xsl:template>
    
    <xsl:template match="mods:name">
        <xsl:variable name="raw_name">
            <xsl:call-template name="stripParentheticRole">
                <xsl:with-param name="value" select="mods:namePart[1]"/>
            </xsl:call-template>
        </xsl:variable>
        <!-- normalize-space handles a stray leading/trailing space a real namePart can have (e.g.
             " Joseph Cashiola (Director)"); the trailing-period strip matches how the note-fallback
             above already cleans up a name (e.g. "Zmekhol, Denise. (Director)" -> "Zmekhol, Denise",
             not "Zmekhol, Denise."). -->
        <xsl:variable name="name" select="replace(normalize-space($raw_name), '[.]$', '')"/>
        <xsl:variable name="roleCode" select="mods:role/mods:roleTerm[@type = 'code']"/>
 
        <xsl:variable name="roleLabelParts">
            <xsl:apply-templates select="mods:role/mods:roleTerm[@type = 'text']" mode="string-join-mode"/>
        </xsl:variable>
        <xsl:variable name="roleLabel" select="lower-case($roleLabelParts)"/>
        <xsl:choose>
            <xsl:when test="$roleCode = 'drt'">
                <!-- A single namePart occasionally names two co-directors at once, a cataloging
                     shortcut rather than two separate mods:name elements, e.g. "Anreas Dalsgaard and
                     Obaidah Zytoon (Director)" (confirmed real example); local:splitCoDirectorNames
                     splits it the same way it already does for the note-fallback above (see its own
                     comment for the safety check that keeps a genuine shared-surname name, e.g. "Andrea
                     and Peter Hylands", from being wrongly split in two). -->
                <xsl:for-each select="local:splitCoDirectorNames($name)">
                    <field name="author_director_tsearch_stored"><xsl:value-of select="." /></field>
                    <field name="author_added_entry_tsearch_stored"><xsl:value-of select="." /></field>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="$roleCode = 'aut'">
                <field name="author_tsearchf_stored"><xsl:value-of select="$name" /></field>
            </xsl:when>
            <xsl:when test="$roleCode = 'prf'">
                <field name="performers_tsearch_stored"><xsl:value-of select="$name" /></field>
                <field name="author_added_entry_tsearch_stored"><xsl:value-of select="$name" /></field>
            </xsl:when>
            <xsl:otherwise>
                <field name="author_tsearchf_stored"><xsl:value-of select="concat($name, ' (', $roleLabel, ')')" /></field>
            </xsl:otherwise>
        </xsl:choose>
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
    
    <xsl:template match="mods:relatedItem[@type='series']/mods:titleInfo/mods:title">
        <field name="title_series_tsearchf_stored">
            <xsl:value-of select="text()"/>
        </field>
    </xsl:template>
    
    <xsl:template match="mods:relatedItem[@displayLabel]">
        <field name="url_label_supp_str_stored">
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
    
    <!-- Shared cleanup for a captured credit-line value (everything after a "Director:" or
         "Directed by" label): cuts off a following role sharing the same line, then splits
         remaining comma-separated names into individual <name> elements. Used by the director
         fallback above; kept here so both label patterns stay in sync. -->
    <!-- "(<short verb phrase> )?(Co-)?directed by <name>"; a verb-phrase credit with no colon or comma
         between label and name. The optional leading phrase, capped at 45 characters of letters/spaces/
         commas/hyphens (no periods, so it can't reach across a sentence boundary), covers both the plain
         form ("Directed by Donna Read", "Co-directed by X and Y") and a compound form naming other
         contributions by the same person first (e.g. "written and directed by Madeleine Hunt-Ehrlich",
         "produced, written and directed by X"). -->
    <!-- Covers two structurally different narrative forms, both gated in the dispatch xsl:choose above
         (not re-checked here, since the gate already decided this segment qualifies):
           - "a film by <name>" (no verb list at all; DirectorMixin.java explicitly treats this as
             directing-equivalent on its own).
           - A list of one or more past-participle verbs joined by commas/"&"/"and" (in any order,
             "directed" need not be adjacent to "by"), ending in "by", e.g. "written, directed &amp;
             produced by X", "produced and directed by X", "director, camera, and editing by X" (mixed
             noun/verb forms), "staged and directed for television by X" (an extra "for X" phrase before
             "by" is tolerated). The dispatch gate separately requires the word "direct" to appear
             somewhere in the segment, so a verb list missing it entirely (e.g. "created and performed
             by X", with no directing verb at all) is correctly NOT treated as a director credit.
         Extraction is the same for both: strip everything up to and including the LAST "by" (greedy
         ".*", so it anchors on the final occurrence rather than an earlier incidental one), tolerating
         an optional square-bracket around "by" for a cataloger's editorial insertion (e.g. "written &amp;
         directed &amp; produced [by] X, Y" where the source credits omitted the word and a cataloger
         supplied it). Case-insensitive throughout via the 'i' flag rather than spelled-out [Ww]-style
         character classes, since matches()/replace() (unlike this Saxon version's analyze-string; see
         the note on the dispatch regex's length cap elsewhere in this file) handle flags correctly. -->
    <!-- The ordinary per-segment dispatch: normalizes any real newlines left in $block_text to the same
         "; " delimiter already used between roles on a single line, then tries each of the four
         templates below in turn per resulting segment. Factored out from the main per-note loop so it
         can be shared between a block that's just one continuous run of text (the common case, and the
         only case before blank-line-delimited blocks were handled) and a block that didn't match the
         blank-line "label alone, then one name per line" shape above. -->
    <xsl:template name="emitCreditNamesFromBlock">
        <xsl:param name="block_text" required="yes"/>
        <xsl:variable name="normalized" select="replace($block_text, '\n', '; ')"/>
        <xsl:variable name="segments" select="tokenize($normalized, ';')"/>
        <xsl:for-each select="1 to count($segments)">
            <xsl:variable name="i" select="."/>
            <!-- A trailing "[and others]"/"and others" (a common cataloging convention for an incomplete
                 credit list, e.g. "director, Justin Maine [and others]") is stripped from the WHOLE
                 segment up front, before the dispatch choice below: left in place, the segment would end
                 in a closing "]" and get wrongly routed to the parenthetical dispatch (meant for "Name
                 (Role)" display forms), which then finds no director-role word inside "[and others]" and
                 gives up entirely, rather than ever reaching the ordinary comma dispatch that would
                 otherwise find "Justin Maine" correctly. The same phrase is also stripped later, in
                 emitCreditNames, for paths that don't go through this per-segment pre-strip (e.g. a
                 narrative "by X [and others]" credit, where the phrase sits inside the captured name
                 text rather than at the segment's own end). -->
            <xsl:variable name="segment" select="replace(normalize-space($segments[$i]), '\s+\[?and[ ]others\]?\.?$', '', 'i')"/>
            <xsl:if test="$segment != ''">
                <!-- Cross-segment reversed name: a record sometimes credits one person per LINE as
                     "Lastname, Firstname" with their role list on its OWN following line instead of in
                     the same comma-joined segment, e.g. "Cortellesi, Paola; film director, screenwriter,
                     actor" (newline-to-semicolon normalization turns each line into its own segment, so
                     the name and its roles end up as two separate, adjacent segments rather than one).
                     Confirmed by several real records (Cortellesi; Mendonca Filho; Dornelles; Rondon;
                     Zapata). Detected here, looking at THIS segment and the one immediately before it:
                     if THIS segment is made ENTIRELY of comma-joined role words with at least one
                     director-related (exactly the shape a role-only line takes), and the PRECEDING
                     segment looks like a bare two-piece "Lastname, Firstname" (neither comma-token is
                     itself a role word, so it wasn't already handled as an ordinary same-segment credit),
                     the preceding segment is emitted as the name here. The preceding segment's own turn
                     through the dispatch below (on the previous loop iteration) already produced nothing
                     for it, since neither of its two tokens is a role word; the current segment's own
                     turn (just below, after this) also safely produces nothing on its own, since a
                     bare role list has no name in it for the ordinary dispatch to find, so this adds a
                     result without risk of double-emitting the same name twice. -->
                <xsl:variable name="prevSegment" select="if ($i gt 1) then normalize-space($segments[$i - 1]) else ''"/>
                <xsl:variable name="prevTokens" select="if ($prevSegment != '') then (for $t in tokenize(local:protectSuffixCommas($prevSegment), ',')[normalize-space(.) != ''] return local:restoreSuffixCommas($t)) else ()"/>
                <xsl:variable name="segTokens" select="tokenize($segment, ',')[normalize-space(.) != '']"/>
                <xsl:if test="exists($segTokens)
                              and (every $t in $segTokens satisfies local:isRoleWord(normalize-space($t)))
                              and (some $t in $segTokens satisfies local:containsDirectorWord(normalize-space($t)))
                              and count($prevTokens) = 2
                              and not(local:isRoleWord(normalize-space($prevTokens[1])))
                              and not(local:isRoleWord(normalize-space($prevTokens[2])))">
                    <!-- Emits the combined "Lastname, Firstname" directly, NOT via emitCreditNames (whose
                         own comma-split would otherwise re-split this one name back into two, exactly the
                         same reasoning as the existing same-segment reversed-name branch elsewhere in
                         this file). -->
                    <xsl:variable name="candidate" select="concat(normalize-space($prevTokens[1]), ', ', normalize-space($prevTokens[2]))"/>
                    <xsl:if test="not(matches(lower-case($candidate), $implausibleNameMarker))
                                  and string-length($candidate) le $maxPlausibleNameLength
                                  and count(tokenize($candidate, '\s+')) le $maxPlausibleNameWords">
                        <name><xsl:value-of select="$candidate"/></name>
                    </xsl:if>
                </xsl:if>
                <xsl:choose>
                    <!-- "a film by" is tolerated with an arbitrary short leading phrase before it (e.g.
                         "Baby Yar Holocaust Memorial Center and Atoms & Void present a film by Sergei
                         Loznitsa"), unlike the verb-list check below, which requires its prefix to be
                         made ENTIRELY of recognized verbs; "a film by" is a complete, self-contained
                         signal on its own (per DirectorMixin.java) that doesn't need a "direct" root
                         anywhere, so leading company/preamble text here is safe to allow generically.
                         German "ein/eine/einem film von X" is accepted the same way, confirmed against a
                         real example ("...präsentieren; einem film von Christian Petzold").
                         The verb-list's "by" also accepts "por" (Spanish/Portuguese), "par" (French), and
                         "da" (Italian), its "&amp;"/"and" connector also accepts "et" (French, needed for
                         "ecrit, produit et realise par X"), and its verb vocabulary includes a few
                         confirmed non-English past participles: "dirigid[oa]" (Spanish/Portuguese
                         "directed"), "r[ée]alis[ée]" (French "directed/made"), "ecrit" (French "written"),
                         "produit" (French "produced"), "diretto"/"diretta" (Italian "directed"),
                         "scritto"/"scritta" (Italian "written", e.g. "scritto e diretto da X"; Italian
                         "e" as "and" is already covered by the connector list elsewhere, which Portuguese
                         also uses). The "contains 'direct'" gate is replaced with
                         local:mentionsDirectingBeforePreposition, which recognizes these same non-English
                         directing roots (see its own comment) instead of requiring the English word. -->
                    <xsl:when test="matches($segment, '^([A-Za-z][A-Za-z0-9 ,&amp;\-]{0,60}?)?(a|ein|eine|einem) film (by|von)[ \t]*.+$', 'i')
                                    or (matches($segment, '^([A-Za-z][A-Za-z0-9 ,&amp;\-]{0,30}? )?(\[?(co-?)?(written|produc(e|ed|ing|er)|direct(ed|ion|ing)?|director|edit(ed|ing|or)?|camera|cinematography|film(ed|ing)?|photograph(ed|ing)?|creat(ed|ing)?|shot|shooting|perform(ed|ing)?|stag(ed|ing)?|narrat(ed|ing)?|dirigid[oa]|r[ée]alis[ée]|[ée]crit|produit|diretto|diretta|scritto|scritta)\]?[,]?[ ]*(&amp;|and|et)?[ ]*)+(for [a-z]+ )?\[?(by|por|par|da)\]?[ \t]*.+$', 'i')
                                        and local:mentionsDirectingBeforePreposition($segment))">
                        <xsl:call-template name="emitNarrativeCreditNames">
                            <xsl:with-param name="segment" select="$segment"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="contains($segment, ':')">
                        <xsl:call-template name="emitColonCreditNames">
                            <xsl:with-param name="label" select="normalize-space(substring-before($segment, ':'))"/>
                            <xsl:with-param name="value" select="substring-after($segment, ':')"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- The "(...)"/"[...]" must be at the very END of the segment (nothing but an
                         optional trailing period after the last closing mark), not merely present
                         SOMEWHERE in it; this distinguishes the real "Name (Role)(Role)" display form
                         (brackets always trailing) from a nickname embedded mid-name in an otherwise
                         ordinary comma-style credit, e.g. "directors, Roni Ninio, Yaakov (Yankul)
                         Goldwasser"; without this check, that segment wrongly went to
                         emitParentheticalCreditNames (which found nothing role-like inside "(Yankul)"
                         and gave up), instead of falling through to emitCommaCreditNames, which correctly
                         handles it once it gets the chance. Square brackets are accepted as an
                         alternative to parens (e.g. "Anat Halachmi [producer and director]"); the regex
                         doesn't require matching bracket TYPES to pair up, just some opener and some
                         closer, which is a little loose but in practice never sees a real mismatch. -->
                    <xsl:when test="((contains($segment, '(') and contains($segment, ')'))
                                     or (contains($segment, '[') and contains($segment, ']')))
                                    and matches($segment, '[)\]][ \t]*[.]?$')">
                        <xsl:call-template name="emitParentheticalCreditNames">
                            <xsl:with-param name="segment" select="$segment"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- The "not starts with 'of '" guard stops a false-friend role like "DIRECTOR OF
                         PHOTOGRAPHY" (as one single-line segment, e.g. "DIRECTOR OF PHOTOGRAPHY\nJohn
                         Smith") from being wrongly treated as "DIRECTOR <name>": the remainder after
                         stripping "director " is "OF PHOTOGRAPHY", which starts with a capital letter
                         (especially in an ALL-CAPS line) and so satisfied the existing capital-letter
                         check even though "Of" is never the start of a real name here. This is a
                         DIFFERENT code path from local:isSplitFalseFriendLabel (which guards the
                         blank-line-block case where the label and "of ..." sit on separate lines); this
                         one guards the case where they're on the SAME line/segment instead. -->
                    <xsl:when test="not(contains($segment, ','))
                                    and matches($segment, '^(co-?)?director[ \t]', 'i')
                                    and not(matches(replace($segment, '^(co-?)?director[ \t]+', '', 'i'), '^of[ \t]', 'i'))
                                    and matches(replace($segment, '^(co-?)?director[ \t]+', '', 'i'), '^[A-ZÀ-Þ].*$')">
                        <xsl:call-template name="emitColonlessCreditNames">
                            <xsl:with-param name="segment" select="$segment"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="emitCommaCreditNames">
                            <xsl:with-param name="segment" select="$segment"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
 
    <xsl:template name="emitNarrativeCreditNames">
        <xsl:param name="segment" required="yes"/>
        <xsl:call-template name="emitCreditNames">
            <!-- The boundary checks around "by"/"por"/"par"/"von" (rather than just "\[?by\]?") stop this
                 from matching one of these as a mere substring of an unrelated word earlier in the
                 segment, e.g. "Baby Yar Holocaust Memorial Center and Atoms &amp; Void present a film by
                 Sergei Loznitsa" has "by" embedded in "Baby" itself, and "par" would otherwise match
                 inside an ordinary English word like "part"; without the boundary, that's the FIRST
                 match the lazy search finds, stripping far more than intended and leaving a candidate
                 that gets rejected by the plausibility guard for being too long, rather than ever
                 reaching the real name. "por"/"par" (Spanish/Portuguese/French "by"), "von" (German "by",
                 for "ein film von X"), and "da" (Italian "by", for "scritto e diretto da X") are accepted
                 alongside "by" itself. \b isn't available in
                 this XPath version (see the note on the narrative dispatch regex's length cap elsewhere
                 in this file), so the boundary is approximated the same way as there: a non-letter or the
                 start/end of the string. -->
            <xsl:with-param name="raw_line" select="replace($segment, '^.*?(^|[^a-zA-Z])\[?(by|por|par|von|da)\]?([^a-zA-Z]|$)[ \t]*', '', 'i')"/>
        </xsl:call-template>
    </xsl:template>
 
    <!-- "<label>: <name(s)>" where <label> names a directing role, possibly combined with other
         roles. Safe to accept an arbitrarily long/compound label here because the colon marks the
         name's start unambiguously, unlike the comma-only case below. -->
    <xsl:template name="emitColonCreditNames">
        <xsl:param name="label" required="yes"/>
        <xsl:param name="value" required="yes"/>
        <xsl:if test="local:isDirectorLabel($label)">
            <xsl:call-template name="emitCreditNames">
                <!-- Strips a SECOND leading colon the value can still have, e.g. a "Label: : Name"
                     double-colon credit (whatever its original cause: a stray separator, two merged
                     fields) only has its FIRST colon consumed by the caller's substring-before/after
                     split; a stray leading colon isn't whitespace, so normalize-space alone won't remove
                     it, and left in place it ends up stuck to the front of the extracted name (e.g.
                     ": Carlos Araya Diaz" instead of "Carlos Araya Diaz"). -->
                <xsl:with-param name="raw_line" select="replace(normalize-space($value), '^:\s*', '')"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
 
    <!-- "<name> (<role>)(<role>)..." or "<name> (<role>, <role>, ...)": one or more parenthesized role
         tags immediately after a name, e.g. "CJ Hunt (Film director)(Screenwriter)" or "Eli Steele
         (Writer, Editor, Director, Producer)". Every "(...)" group in the segment is pulled out and its
         contents comma-split (so both the adjacent-parens style and the single-paren comma-list style
         are treated the same way), then each resulting role phrase is checked with the same
         local:isDirectorLabel used for colon labels above (so "Film director" counts, "Director of
         Photography" doesn't). The name is everything before the first "(". -->
    <xsl:template name="emitParentheticalCreditNames">
        <xsl:param name="segment" required="yes"/>
        <xsl:variable name="roles_text">
            <xsl:analyze-string select="$segment" regex="[(\[]([^()\[\]]*)[)\]]">
                <xsl:matching-substring><xsl:value-of select="regex-group(1)"/><xsl:text>,</xsl:text></xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:variable name="role_tokens" select="tokenize(string($roles_text), ',')[normalize-space(.) != '']"/>
        <!-- The name is everything before whichever bracket type opens first. -->
        <xsl:variable name="first_open" select="
            if (not(contains($segment, '(')) or (contains($segment, '[') and string-length(substring-before($segment, '[')) lt string-length(substring-before($segment, '(')))) then '['
            else '('"/>
        <xsl:variable name="name_part" select="normalize-space(replace(substring-before($segment, $first_open), '[,]+$', ''))"/>
        <!-- Safety check: the text before the "(...)" must look like ONE name, not a comma-separated
             list of several people (e.g. a cast list where a trailing "(...co-directors)" tag's scope
             over the preceding names is genuinely ambiguous: does it cover just the last name, or
             several?). Capped at 2 tokens to allow a reversed "Last, First" name without allowing a
             real list through. -->
        <xsl:if test="exists($role_tokens) and (some $r in $role_tokens satisfies local:isDirectorLabel(normalize-space($r)))
                      and $name_part != '' and count(tokenize(local:protectSuffixCommas($name_part), ',')) le 2">
            <xsl:call-template name="emitCreditNames">
                <xsl:with-param name="raw_line" select="$name_part"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
 
    <!-- "(Co-)?Director <name>" with no colon, "by", or comma at all (only tried when nothing else
         matched and the segment has no comma, so it never competes with the comma-style dispatch).
         Deliberately narrow: requires the very next character after "Director " to be a capital letter,
         so it only fires on what already looks like a Title-Case name. Cuts at the first " / " (seen in
         real records chaining several unlabeled role/name pairs this way, e.g. "Director X / Dir. of
         Photography Y / Sound Z"), the same idea as the "|" cut in emitCreditNames but for this
         slash-as-pair-separator usage rather than the slash-as-role-compound usage handled inside
         local:isRoleWord; the two don't conflict because this cut only ever applies to the name
         text, after the role word has already been recognized. -->
    <xsl:template name="emitColonlessCreditNames">
        <xsl:param name="segment" required="yes"/>
        <!-- Case-insensitive replace() to strip the label (so "DIRECTOR Ken Loach" works, not just
             "Director Ken Loach"), kept separate from the dispatch gate's case-SENSITIVE check that the
             name itself starts with a capital letter; a single combined case-insensitive regex can't
             enforce the latter, since the flag would also let the capital-letter check match lowercase. -->
        <xsl:variable name="raw_line" select="replace($segment, '^(co-?)?director[ \t]+', '', 'i')"/>
        <xsl:variable name="cut_slash" select="if (contains($raw_line, ' / ')) then substring-before($raw_line, ' / ') else $raw_line"/>
        <xsl:call-template name="emitCreditNames">
            <xsl:with-param name="raw_line" select="$cut_slash"/>
        </xsl:call-template>
    </xsl:template>
 
    <!-- "<role(s)>, <name(s)>" or "<name>, <role(s)>" with no colon at all (the MARC statement-of-
         responsibility convention). A comma here does double duty; separating roles from each other
         AND separating the role list from the name; so this only extracts a name where that boundary
         can be found safely, using local:isRoleWord/local:containsDirectorWord (above) to recognize a
         role word (bare, &amp;/and-compound, or a "/"-joined list like "Director/producer/writer" or
         "Producer/director" in either order):
 
           - Reversed "Name, Director[, Role, Role...]": the FIRST token isn't itself a role word, and
             EVERY token after it is (covers both the simple "Name, Director" case and a longer trailing
             role list like "Daphne Di Cinto, director, writer, producer").
           - Forward "Role(s), Name(s)": a run of leading tokens (checked up to 4, which covers every
             real compound-role case seen) that ALL match a recognized role word.
         Either way, at least one matched role token must actually name directing, not just some other
         role. An unrecognized role word anywhere in the required run stops the check rather than
         guessing; it's left for manual review instead of risking a wrong name. Capped at 6 tokens total
         (plenty for any real compound-role case seen) so a long, unrelated comma-heavy sentence can't
         accidentally satisfy "every token is a short role word" by chance. -->
    <xsl:template name="emitCommaCreditNames">
        <xsl:param name="segment" required="yes"/>
        <xsl:variable name="tokens" select="for $t in tokenize(local:protectSuffixCommas($segment), ',') return local:restoreSuffixCommas(normalize-space($t))"/>
        <xsl:variable name="n" select="count($tokens)"/>
        <xsl:choose>
            <!-- Reversed "Lastname, Firstname, role, role..." (a two-piece name before the role list,
                 e.g. "Salgado, Richard, film director, screenwriter."): tried first, since whenever it
                 applies, the simpler one-token reversed check just below would see tokens[1] (the first
                 name) and wrongly conclude it isn't a role word) failing the SAME way it would for a
                 real one-piece name, but here that's wrong, because tokens[1] is actually part of the
                 name, not the start of the role list. Capped at 7 tokens total (one more than the
                 one-piece case, for the extra name token) for the same reason as there. Emits the name
                 directly (bypassing emitCreditNames) since its comma-split would otherwise re-split
                 "Lastname, Firstname" back into two separate people. -->
            <xsl:when test="$n ge 3 and $n le 7
                             and not(local:isRoleWord($tokens[1])) and not(local:isRoleWord($tokens[2]))
                             and (every $t in subsequence($tokens, 3) satisfies local:isRoleWord($t))
                             and (some $t in subsequence($tokens, 3) satisfies local:containsDirectorWord($t))">
                <xsl:variable name="candidate" select="concat($tokens[1], ', ', $tokens[2])"/>
                <xsl:if test="not(matches(lower-case($candidate), $implausibleNameMarker))
                              and string-length($candidate) le $maxPlausibleNameLength
                              and count(tokenize($candidate, '\s+')) le $maxPlausibleNameWords">
                    <name><xsl:value-of select="$candidate"/></name>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$n ge 2 and $n le 6
                             and not(local:isRoleWord($tokens[1]))
                             and (every $t in subsequence($tokens, 2) satisfies local:isRoleWord($t))
                             and (some $t in subsequence($tokens, 2) satisfies local:containsDirectorWord($t))">
                <xsl:call-template name="emitCreditNames">
                    <xsl:with-param name="raw_line" select="$tokens[1]"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="prefixLen" select="
                    if ($n ge 5 and (every $t in subsequence($tokens, 1, 4) satisfies local:isRoleWord($t))) then 4
                    else if ($n ge 4 and (every $t in subsequence($tokens, 1, 3) satisfies local:isRoleWord($t))) then 3
                    else if ($n ge 3 and (every $t in subsequence($tokens, 1, 2) satisfies local:isRoleWord($t))) then 2
                    else if ($n ge 2 and local:isRoleWord($tokens[1])) then 1
                    else 0"/>
                <xsl:if test="$prefixLen gt 0 and (some $t in subsequence($tokens, 1, $prefixLen) satisfies local:containsDirectorWord($t))">
                    <xsl:variable name="remaining" select="subsequence($tokens, $prefixLen + 1)"/>
                    <!-- Stop at the first remaining token that is ITSELF a recognized role word, which
                         signals a different, unrelated credit starting here with no semicolon to mark
                         the boundary (a cataloging style inconsistency, not more co-directors), e.g.
                         "director and screenwriter, David Bornstein, camera, Eric Bergeron, Christian
                         Mignard": "camera" starts a different credit entirely, and Eric Bergeron/
                         Christian Mignard are NOT additional directors, just that credit's names.
                         Without this, every token after the role prefix was taken as a name
                         unconditionally. -->
                    <xsl:variable name="stop_at" select="
                        for $i in (1 to count($remaining)) return if (local:isRoleWord($remaining[$i])) then $i else ()"/>
                    <xsl:variable name="names_to_use" select="
                        if (exists($stop_at)) then subsequence($remaining, 1, min($stop_at) - 1) else $remaining"/>
                    <!-- A further split via local:splitCoDirectorNames (not just the comma already used
                         to produce $names_to_use) lets a token like "G. Kozintsev and L. Trauberg" come
                         out as two separate directors rather than one combined string, matching how
                         emitCreditNames does the same split elsewhere. -->
                    <xsl:for-each select="$names_to_use[normalize-space(.) != '']">
                        <xsl:for-each select="local:splitCoDirectorNames(.)">
                            <!-- Strips a leading "and "/"&amp; " an Oxford-comma list can leave on its
                                 last comma-split token (see the matching note in emitCreditNames). -->
                            <xsl:variable name="candidate" select="replace(replace(normalize-space(.), '^(and|&amp;)[ ]+', '', 'i'), '[.]$', '')"/>
                            <xsl:if test="not(matches(lower-case($candidate), $implausibleNameMarker))
                                          and string-length($candidate) le $maxPlausibleNameLength
                                          and count(tokenize($candidate, '\s+')) le $maxPlausibleNameWords">
                                <name><xsl:value-of select="$candidate"/></name>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
 
    <xsl:template name="emitCreditNames">
        <xsl:param name="raw_line" required="yes"/>
        <xsl:variable name="no_pipe" select="if (contains($raw_line, '|')) then substring-before($raw_line, '|') else $raw_line"/>
        <!-- An informal trailing "und freunden"/"and friends" (German/English "and friends", seen after
             "ein film von X und freunden") is stripped before anything else: it's not a second director,
             just an informal credit flourish, and since "freunden"/"friends" isn't itself a name, simply
             splitting on the connector (the way a real co-director pair would be) would wrongly produce
             a second, nonsense "director". Confirmed real example: "Ein film von Anke Ertner und
             freunden" should yield just "Anke Ertner", not "Anke Ertner und freunden" whole, nor "Anke
             Ertner" + "freunden" as two separate people. -->
        <!-- Likewise an informal trailing "[and others]"/"and others" (a common cataloging convention
             for an incomplete credit list, e.g. "director, Justin Maine [and others]") is stripped for
             the same reason: "others" isn't a name, so leaving the phrase attached (or splitting on
             "and" to produce a second, nonsense "director" named "others") would both be wrong. -->
        <xsl:variable name="no_friends" select="replace(replace($no_pipe, '\s+(und[ ]freunden|and[ ]friends)\.?$', '', 'i'), '\s+\[?and[ ]others\]?\.?$', '', 'i')"/>
        <!-- See local:periodLabelCut's own comment for the full reasoning (role-word-aware cut). -->
        <xsl:variable name="cut" select="local:periodLabelCut($no_friends)"/>
        <!-- Comma-split first, then each resulting piece is further split on " and "/" &amp; " via
             local:splitCoDirectorNames when that looks safe (see its own comment): two co-credited
             people joined by the word "and" or an ampersand (e.g. "by G. Kozintsev and L. Trauberg",
             "Mark Achbar &amp; Peter Wintonick") are two separate directors just as much as a
             comma-joined pair is, and should come out as two separate field values rather than one
             combined string. -->
        <xsl:for-each select="tokenize(local:protectSuffixCommas(normalize-space($cut)), ',\s*')[normalize-space(.) != '']">
            <xsl:for-each select="local:splitCoDirectorNames(local:restoreSuffixCommas(.))">
                <!-- An Oxford-comma list ("X, Y, and Z") leaves a leading "and "/"&amp; " on the LAST
                     comma-split token (the comma-split above only removes the comma and the whitespace
                     right after it, not a connector word that happens to follow), e.g. "produced by
                     Andrew Harries and Mick Csaky" after an earlier name was already comma-separated
                     yielding "and Mick Csaky" as its own token; stripped here before the plausibility
                     check so the result is "Mick Csaky", not "and Mick Csaky". -->
                <xsl:variable name="candidate" select="replace(replace(normalize-space(.), '^(and|&amp;)[ ]+', '', 'i'), '[.]$', '')"/>
                <xsl:if test="not(matches(lower-case($candidate), $implausibleNameMarker))
                              and string-length($candidate) le $maxPlausibleNameLength
                              and count(tokenize($candidate, '\s+')) le $maxPlausibleNameWords">
                    <name><xsl:value-of select="$candidate"/></name>
                </xsl:if>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
 
    <xsl:template name="stripParentheticRole">
        <xsl:param name="value" required="yes"/>
        <!-- Without flags="m", $ anchors strictly at the end of the whole string. If $value ever has
             a trailing CR (the same &#xD;-entity encoding seen in MODS note fields; see the Director
             extraction fallback above for the full explanation), the match silently fails: "." can't
             consume the CR, and "$" sits one character further along, right after it. No real namePart
             in the current sample data has this, but the fix is cheap and this template runs on every
             mods:name in the record, so it's stripped here too for safety. -->
        <xsl:variable name="clean_value" select="translate($value, '&#13;', '')"/>
        <!-- The repeated group "(\s*\([^()]+\))+" strips ALL trailing parenthetical annotations, not
             just the outermost/last one: a real namePart can chain more than one, e.g. "Siegel, Allan
             (Motion picture editor) (Director)", where the OLD single-group pattern's greedy ".*" would
             consume right up through the first parenthetical too, leaving "Siegel, Allan (Motion
             picture editor)" with that first annotation still stuck to the name. -->
        <xsl:analyze-string select="$clean_value" regex="^(.*?)(\s*\([^()]+\))+$">
            <xsl:matching-substring>
                <xsl:value-of select="regex-group(1)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="$clean_value"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
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
 
</xsl:stylesheet>
 
