<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" 
	xmlns:premis="http://www.loc.gov/premis/v3"
	xmlns:dc="http://purl.org/dc/terms/">
	<xsl:output method="xml" indent="yes"/>

<!--the template below matches to the document node of the MediaInfo XML-->
<!--it generates the overall structure of the <aip> and <filelist> sections within the master XML-->
<!--the <aip> section calls named templates to populate the fields that are required for every aip-->
<!--the <filelist> section uses an overarching applied template that references multiple matched templates located further in the stylesheet; a filelist will only be included in AIPs that contain more than one file-->

	<xsl:template match="/">
	<master>
		<dc:title><xsl:call-template name="aip-title"/></dc:title>
        <dc:rights>http://rightsstatements.org/vocab/InC/1.0/</dc:rights><!--In Copyright is the default rights statement. You can manually change or make it a variable if needed-->
		<aip>
			<premis:object>
				<xsl:call-template name="aip-id"/>
				<xsl:call-template name="aip-version"/>
				<xsl:call-template name="object-category"/>
				<premis:objectCharacteristics>
					<xsl:call-template name="aip-size"/>
					<xsl:call-template name="aip-unique-formats"/>
				</premis:objectCharacteristics>
				<xsl:call-template name="collection-id"></xsl:call-template>
			</premis:object>
		</aip>
		
		<!--the <filelist> section is wrapped by an <xsl:if> test; a filelist section is output in the master.xml only if mediainfo.xml contains more than one 'File' node; see the $file-nodes global variable below-->
			<xsl:if test="$file-nodes > 1">
				<filelist>
				<xsl:apply-templates select="//track[@type='General']"/>
				</filelist>
			</xsl:if>
		</master>
</xsl:template>

	  
<!--GLOBAL VARIABLES DECLARED BELOW CAN BE CALLED ANYWHERE IN THE STYLESHEET-->

    <!--$uri: the unique identifier for the group in the ARCHive (digital preservation system), which is used with all other identifiers-->
    <xsl:variable name="uri"><xsl:text>http://archives.libs.uga.edu/russell<xsl:text></xsl:variable>
        
    <!--$aip-id: inserts the value for the identifier type (group uri) and the aip-id from variables-->
    <!--includes conditional tests for media vs. metadata aips; tests for file extensions found in MediaInfo XML to parse whether to put "_media" or "_metadata" into the aip-id-->
	<xsl:variable name="aip-id">
		<xsl:choose>
  		<xsl:when test="//FileExtension[contains(., 'xml')] or //FileExtension[contains(., 'pdf')] or //FileExtension[contains(., 'doc')]">
            <!--the regex below matches the naming conventions that Russell Oral History and Media uses: rbrl###abcde-###-->
            <!--the numbers in curly braces specify the expected number of digits/characters to look for; e.g. there can be between 2-5 letters identifying a collection-->
  			 <xsl:analyze-string select="$aip-filepath/FolderName" regex="(rbrl\d{{3}}\w{{2,5}}-\w.*)/objects">
  			 	<xsl:matching-substring>
  			 	<xsl:value-of select="regex-group(1)"/><xsl:text>_metadata</xsl:text>
  			 	</xsl:matching-substring>
   			</xsl:analyze-string>
   		</xsl:when>
   		
   		<xsl:when test="//FileExtension[contains(., 'mov')] or //FileExtension[contains(., 'wav')] or //FileExtension[contains(., 'mp3')] or //FileExtension[contains(., 'dv')]">
	   		<xsl:analyze-string select="$aip-filepath/FolderName" regex="(rbrl\d{{3}}\w{{2,5}}-\w.*)/objects">
	   			<xsl:matching-substring>
	   			<xsl:value-of select="regex-group(1)"/><xsl:text>_media</xsl:text>
	   			</xsl:matching-substring>
	   		</xsl:analyze-string>
   		</xsl:when>
  		</xsl:choose>
	</xsl:variable>
    
    <!--$coll-id : regex for formatting the collection ID-->
    <xsl:variable name="coll-id">
        <xsl:analyze-string select="$aip-filepath/FileName" regex="(rbrl\d{{2,4}})">
            <xsl:matching-substring><xsl:sequence select="regex-group(1)"/></xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:variable>
    
    <!--$file-nodes: counts number of 'file' nodes that are children of //Mediainfo parent; used in master template above to do conditional test for <premis:objectCharacteristics> and <filelist> section-->
    <xsl:variable name="file-nodes">
        <xsl:value-of select="count(//Mediainfo/File)"/>
    </xsl:variable>
    
    <!--$aip-filepath: caches the lengthy filepath since it will be used repeatedly in other portions of the stylesheet-->
    <xsl:variable name="aip-filepath" select="//Mediainfo/File[1]/track[@type='General'][1]"/>
	
    <!--$mediainfo-version : select the XPath for Mediainfo version-->
	<xsl:variable name="mediainfo-version" select="//Mediainfo/@version"/>
	
    <!--$aip-size: ARCHive requires <premis:size> to be a whole number; the fn:format-number function is called to output the total file size as an integer number (designated by the '#' at the end) -->
	<xsl:variable name="aip-size">
		<xsl:value-of select="format-number(sum(//Mediainfo/File/track[@type='General']/FileSize), '#')"/>
	</xsl:variable>
	
   
    
<!--NAMED TEMPLATES: AIP LEVEL INFORMATION-->
<!--named templates allow for the extraction of specific relevant information into required fields-->
<!--since fields in the aip-level section do not repeat, named templates were chosen as the most appropriate option for processing this information-->
	
	
<!--the aip-title template below contains four conditional 'when' tests and a default condition-->
	<xsl:template name="aip-title">
	
	<xsl:choose>
		
<!-- 1. Tests whether 'FileName' tag contains the string '_pm' ; if it does, it runs a different regex that eliminates the '_pm' from the output-->
    <xsl:when test="$aip-filepath[contains(FileName, '_pm')]">
        <xsl:analyze-string select="$aip-filepath/FileName[1]" regex="(rbrl\d{{2,5}}\w.*)_pm">
            <xsl:matching-substring>
                <xsl:value-of select="regex-group(1)"/><xsl:text>_media</xsl:text>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:when>
		
<!-- 2. Tests first if contains certain strings in the FileName tag according to the naming conventions for such files-->
<!--then the regex screens out those words which come after the underscore (i.e. _transcript, _ohms, _notes, or _dg)-->
    <xsl:when test="//track[contains(FileExtension, 'xml') or contains(FileExtension, 'pdf') or contains(FileExtension, 'doc')]">
        <xsl:analyze-string select="$aip-filepath/FileName[1]" regex="(rbrl\d{{3}}\w{{2,5}}-\w[a-z0-9.%-]{{2,10}})_\w.*">
            <xsl:matching-substring>
                <xsl:value-of select="regex-group(1)"/><xsl:text>_metadata</xsl:text>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:when>
		
<!-- 3. Tests for when an aip contains multiple files, the regex below pulls information from the FolderName rather than FileName tag
<!-- Meant to screen out names of individual files, since they do no accurately represent the title of the whole aip-->
    <xsl:when test="$file-nodes > 1">
        <xsl:analyze-string select="$aip-filepath/FolderName" regex="(rbrl\d{{3}}\w{{2,5}}-\w.*)/objects">
            <xsl:matching-substring>
                <xsl:value-of select="regex-group(1)"/><xsl:text>_media</xsl:text>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:when>
		
<!-- 4. Tests for when an aip contains file with extension 'mov'-->
    <xsl:when test="//track[contains(FileExtension, 'mov')]">
        <xsl:value-of select="$aip-filepath/FileName"/><xsl:text>_media</xsl:text>
    </xsl:when>	
		
	
<!--Default condition with the broadest regex (only for media aips)-->
		<xsl:otherwise>
			<xsl:analyze-string select="$aip-filepath/FileNameExtension" regex="(rbrl\d{{3}}\w{{2,5}}-\w*).\w{{2,3}}">
				<xsl:matching-substring>
					<xsl:value-of select="regex-group(1)"/>
				</xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:otherwise>
		
	</xsl:choose>
	</xsl:template>
	
	<xsl:template name="aip-id">
		<premis:objectIdentifier>
		<premis:objectIdentifierType><xsl:text>$uri</xsl:text></premis:objectIdentifierType>
            <premis:objectIdentifierValue><xsl:value-of select="$aip-id"/></premis:objectIdentifierValue>
         </premis:objectIdentifier>
	</xsl:template>
    
    <xsl:template name="collection-id">
        <premis:relationship>
            <premis:relationshipType>structural</premis:relationshipType>
            <premis:relationshipSubType>Is Member Of</premis:relationshipSubType>
            <premis:relatedObjectIdentifier>
                <premis:relatedObjectIdentifierType>$uri</premis:relatedObjectIdentifierType>
                <premis:relatedObjectIdentifierValue>
                    <xsl:value-of select="$coll-id"/>
                </premis:relatedObjectIdentifierValue>
            </premis:relatedObjectIdentifier>
        </premis:relationship>
    </xsl:template>

    <!--the default is the number 1; if you need to replace an aip in system, manually change the number of the objectIdentifierValue to reflect the new version of the aip-->
	<xsl:template name="aip-version">
		<premis:objectIdentifier>
			<premis:objectIdentifierType><xsl:text>$uri</xsl:text><xsl:value-of select="$aip-id"/></premis:objectIdentifierType>
			<premis:objectIdentifierValue>1</premis:objectIdentifierValue>
		</premis:objectIdentifier>
	</xsl:template>
	
	<!--examines the number of <File> nodes to determine whether the AIP is a representation (multiple files) or a file (single instance)-->
	<xsl:template name="object-category">
		<premis:objectCategory>
			<xsl:if test="$file-nodes > 1">
				<xsl:text>representation</xsl:text>
			</xsl:if>
			<xsl:if test="$file-nodes = 1">
				<xsl:text>file</xsl:text>
			</xsl:if>
		</premis:objectCategory>
	</xsl:template>
	
	<!--if <FileSize> node is not empty, then outputs the value of the $aip-size variable; otherwise, outputs an empty <premis:size> tag so that master.xml will fail validation and staff will know to check for errors-->
	<xsl:template name="aip-size">
		<xsl:choose>
			<xsl:when test="//FileSize[1] != ''">
				<premis:size><xsl:value-of select="$aip-size"/></premis:size>
			</xsl:when>
			<xsl:otherwise>
				<premis:size/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	

	
	<!--aip format list: gets a unique list of file formats in the aip based on format comparison of all files in aip-->

	<xsl:template name="aip-unique-formats">
        
    <!--if the aip contains only 1 file, then the value of the <Format> tag is used-->
        <xsl:if test="$file-nodes = 1">
            <premis:format>
                <premis:formatDesignation>
                    <premis:formatName><xsl:value-of select="$aip-filepath/Format"/></premis:formatName>
                </premis:formatDesignation>
                    <premis:formatNote>
			<xsl:variable name="track2" select="//Mediainfo/File[1]/track[@type='Video'][1]"/> 
			<xsl:choose>
			<xsl:when test="$aip-filepath[contains(FileExtension, 'mov')]">
				<xsl:text>Format identified by MediaInfo version </xsl:text><xsl:value-of select="$mediainfo-version"/><xsl:text>. File encoded as: </xsl:text>
					<xsl:value-of select="$track2/Encoded_Library, $track2/Format_Commercial, $track2/Format_Profile" separator=" "/><xsl:text>.</xsl:text>
            		</xsl:when>
			<xsl:otherwise>
                        	<xsl:text>Format identified by MediaInfo version </xsl:text><xsl:value-of select="$mediainfo-version"/><xsl:text>.</xsl:text>
			</xsl:otherwise>
			</xsl:choose>
                    </premis:formatNote>
            </premis:format>
        </xsl:if>
	
    <!--first tests if an aip contains multiple files; file sorting and removing of duplicates is only necessary when more than file exists-->
        <xsl:if test="$file-nodes > 1">
	
	<!--2 part choose/when test for format identification and removal of duplicates-->
    
        <xsl:choose>
        
    <!--this first condition tests that the aip does not contain an 'avchd' folder-->
    <!--if it doesn't contain the folder, generates a unique format list based on <Format> tag information-->
        <xsl:when test="//File[2]/track[1][not(contains(CompleteName, 'avchd'))]">
            
            <xsl:for-each-group select="//track[1]" group-by="Format">
            <xsl:sort select="current-grouping-key()" />
                <premis:format>
                    <premis:formatDesignation>
                        <premis:formatName>
                            <xsl:value-of select="Format"/>
                    </premis:formatName>
                    </premis:formatDesignation>
                    <premis:formatNote>
			<xsl:variable name="track2" select="//Mediainfo/File[1]/track[@type='Video'][1]"/> 
			<xsl:choose>
			<xsl:when test="$aip-filepath[contains(FileExtension, 'mov')]">
				<xsl:text>Format identified by MediaInfo version </xsl:text><xsl:value-of select="$mediainfo-version"/><xsl:text>. File encoded as: </xsl:text>
					<xsl:value-of select="$track2/Encoded_Library, $track2/Format_Commercial, $track2/Format_Profile" separator=" "/><xsl:text>.</xsl:text>
            		</xsl:when>
			<xsl:otherwise>
                        	<xsl:text>Format identified by MediaInfo version </xsl:text><xsl:value-of select="$mediainfo-version"/><xsl:text>.</xsl:text>
			</xsl:otherwise>
			</xsl:choose>
                    </premis:formatNote>
                </premis:format>
            </xsl:for-each-group>
		
<!--some tracks do not have 'Format' tags; this condition is tested by seeing whether FileExtension has a sibling 'Format' tag-->
<!--only if there is no Format tag, then the FileExtension fields are grouped and sorted and are output with a different Format Note; FileExtensions are used for <File> elements that do have Format tags-->
        <xsl:for-each-group select="//track[1]" group-by="FileExtension[not(following-sibling::Format)]">
        <xsl:sort select="current-grouping-key()" />
            <premis:format>
                <premis:formatDesignation>
                    <premis:formatName>
                        <xsl:value-of select="FileExtension"/>
                </premis:formatName>
                </premis:formatDesignation>
                <premis:formatNote>
                    <xsl:text>Unable to identify format. Instead, file extension identified by MediaInfo version </xsl:text><xsl:value-of select="$mediainfo-version"/><xsl:text>.</xsl:text>
                </premis:formatNote>
            </premis:format>
        </xsl:for-each-group>
    </xsl:when>
	
<!--if the aip contains an 'avchd' folder, then the following fields are output; although a avchd folder contains many files, they are not listed in the <aip> section as unique formats; instead, 'AVCHD' itself is listed as a format with a format note describing the reasons behind that-->
<!--the XPath for the test looks at the track of the second File element; the first File Element will always be for the preservation master .mov file due to the restructing that takes place when the first stylesheet 'mediainfo-cleanup' is run on the MediaInfo XML.-->
	
		<xsl:when test="//File[2]/track[1][contains(CompleteName, 'avchd')]">
			<xsl:variable name="track2" select="//Mediainfo/File[1]/track[@type='Video'][1]"/> <!--locally caches the filepath for the 'Video' track, which appears as the second child of the 'File' parent element-->
			
			<premis:format><!--this first PREMIS format field pulls information about the preservation master file-->
				<premis:formatDesignation>
					<premis:formatName><xsl:value-of select="$aip-filepath/Format"/></premis:formatName>
				</premis:formatDesignation>
				<premis:formatNote>
					<xsl:text>Format identified by MediaInfo version </xsl:text><xsl:value-of select="$mediainfo-version"/><xsl:text>. File encoded as: </xsl:text>
					<xsl:value-of select="$track2/Encoded_Library, $track2/Format_Commercial, $track2/Format_Profile" separator=" "/><xsl:text>.</xsl:text>
				</premis:formatNote>
			</premis:format>
            
			<!--this second PREMIS format field has pre-filled information about the AVCHD directory-->
            <!--rather than listing all the subcomponent files individually in the aip-unique-formats list, AVCHD is listed as the format and files are enumerated in the file list section-->
			<premis:format>
					<premis:formatDesignation>
						<premis:formatName><xsl:text>AVCHD</xsl:text></premis:formatName>
					</premis:formatDesignation>
					<premis:formatNote>A complex directory format that is a composite of sub-component files, enumerated in the AIP-level file list.</premis:formatNote>
			</premis:format>
			</xsl:when>
			
			
	</xsl:choose>
	</xsl:if>
	</xsl:template>
	

<!--OVERARCHING MATCH TEMPLATE FOR FILELIST SECTION-->
<!--this template matches to each track[@type='General'] in the MediaInfo XML-->
<!--it has as its children, the other applied templates and called templates that populate the filelist section-->

	<xsl:template match="//track[@type='General']">
		<premis:object>
			<xsl:apply-templates select="CompleteName" />
			<premis:objectCategory>file</premis:objectCategory>
			<premis:objectCharacteristics>
				<premis:size><xsl:apply-templates select="FileSize"/></premis:size>
				<xsl:apply-templates select="Format_String | FileExtension" />
			</premis:objectCharacteristics>
			<xsl:call-template name="relationship-aip" />
		</premis:object>
	</xsl:template>


<!--MATCHED TEMPLATES: FILELIST SECTION-->
<!--these are the templates that feed into the overaching match template for the filelist section (see the very beginning of the document)-->
<!--each template matches one of the child elements of the //Mediainfo/File/track[@type='General'] parent element-->

	<xsl:template match="CompleteName">
		<premis:objectIdentifier>
			<premis:objectIdentifierType><xsl:text>$uri/</xsl:text><xsl:value-of select="$aip-id" /></premis:objectIdentifierType>
			<premis:objectIdentifierValue>
				<xsl:analyze-string select="." regex=".*/objects/(.*)">
					<xsl:matching-substring><xsl:sequence select="regex-group(1)"/></xsl:matching-substring>
				</xsl:analyze-string>
			</premis:objectIdentifierValue>
		</premis:objectIdentifier>
	</xsl:template>  
	
	<xsl:template match="FileSize">
		<xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="Format_String">
		<premis:format>
			<premis:formatDesignation>
				<premis:formatName><xsl:value-of select="."/></premis:formatName>
			</premis:formatDesignation>
				<premis:formatNote><xsl:text>Format identified by MediaInfo version </xsl:text><xsl:value-of select="$mediainfo-version"/><xsl:text>.</xsl:text></premis:formatNote>
		</premis:format>
	</xsl:template>
	<!--tests for absence of a following-sibling 'Format' element for the 'FileExtension' tag; if no Format tag exists, then value of FileExtension is used for <premis:format> and the text within the <premis:formatNote> tag explains the reason why-->
	<xsl:template match="FileExtension">
		<xsl:if test="not(following-sibling::Format)">
			<premis:format>
				<premis:formatDesignation>
					<premis:formatName><xsl:value-of select="."/></premis:formatName>
				</premis:formatDesignation>
				<premis:formatNote>
					<xsl:text>MediaInfo was unable to identify format. Instead, file extension identified by MediaInfo version </xsl:text>
					<xsl:value-of select="$mediainfo-version"/><xsl:text>.</xsl:text></premis:formatNote>
			</premis:format>
		</xsl:if>
	</xsl:template>

	<xsl:template name="relationship-aip">
		<premis:relationship>
			<premis:relationshipType>structural</premis:relationshipType>
			<premis:relationshipSubType>Is Member Of</premis:relationshipSubType>
			<premis:relatedObjectIdentifier>
				<premis:relatedObjectIdentifierType>$uri</premis:relatedObjectIdentifierType>
				<premis:relatedObjectIdentifierValue>
					<xsl:value-of select="$aip-id"/>
				</premis:relatedObjectIdentifierValue>
			</premis:relatedObjectIdentifier>
		</premis:relationship>
	</xsl:template>
		
</xsl:stylesheet>
