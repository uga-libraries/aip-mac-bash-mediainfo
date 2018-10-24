<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" indent="yes"/>
	<xsl:strip-space elements="*"/>
	
	<!-- Purpose: Mediainfo outputs the File nodes in an unconsistent order; since the XPath functions in the mediainfo-to-master.xsl depend on a consistent order (in which the preservation master media is listed first in the mediainfo.xml), this document restructures the XML so that the media File will 		always show up first in the list-->
	
	<!-- identity transform: copies everything unless there are more specific instructions in another template: maintains the overall document structure; more specific matched templates override general identity transform-->
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>

	<!--for the Mediainfo parent, two matched templates are applied in the order desired in the final output: ProRes file (if it exists) is listed first, followed by any additional files-->
	<xsl:template match="Mediainfo">
	<xsl:copy>
		<!--selects Mediainfo's attributes (in this case the version number), which is used in the mediainfo-to-master.xsl-->
		<xsl:apply-templates select="@*"/>
		<xsl:apply-templates select="File" mode="mov-first"/> <!--the mode specifies that the <File> element that contains the FileExtension 'mov' needs to be placed first when outputting the order of elements-->
		<xsl:apply-templates select="File" mode="general"/> <!--a mode on an applied template allows for greater specificity if a condition needs to be tested for-->
		
	</xsl:copy>
	</xsl:template>
	
	<!--first tests if there is a track that contains the value 'mov' in the FileExtension node; if there is, it then copies that whole File element and its children; otherwise, it copies the rest of the File nodes in order-->
	<xsl:template match="File" mode="mov-first">
		<xsl:if test="track/FileExtension[contains(., 'mov')]">
			<xsl:copy-of select="."/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="File" mode="general">
		<xsl:if test="track/FileExtension[not(contains(., 'mov'))]">
			<xsl:copy-of select="."/>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>
