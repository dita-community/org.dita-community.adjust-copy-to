<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  exclude-result-prefixes="xs xd"
  version="2.0">

<!-- ===================================================
     Implementation of custom @copy-to adjustment.
     
     See d4pAdjustCopyTo.xsl for details.
     
     Copyright (c) 2014 DITA for Publishers

     The input to this transform is a fully-resolved map, e.g.,
     the output of the Open Toolkit mappull process (that is, 
     the copy of the original input map that is in the OT's
     temp directory.
     
     The output is a new single-document map with the @copy-to
     values adjusted as appropriate.
     
     Default mode is a normal identity transform.

     =================================================== -->
  
  <xsl:import href="plugin:org.dita-community.common.xslt:xsl/relpath_util.xsl"/>
  
  <!-- URI of the .job.xml file generated by the base OT processing. -->
  <xsl:param name="job.xml" as="xs:string"/>

  <!-- Use navigation keys to determine source filenames. Default
       is to use first only only key on the topicref.
       
       Default is "no" (nav keys not used).
    -->
  <xsl:param name="use-nav-keys" as="xs:string" select="'no'"/>
  <xsl:variable name="isUseNavKeys" as="xs:boolean"
    select="matches($use-nav-keys, 'yes|true|on|1', 'i')"
  />
  
  <!-- Override existing copy-to values when the topicref would otherwise
       get a copy-to value (e.g., when use-nav-keys is in effect).
       
       Default is "no" (do not override existing copy-to values).
    -->
  <xsl:param name="override-existing-copy-to" as="xs:string" select="'no'"/>
  <xsl:variable name="isOverrideExistingCopyTo" as="xs:boolean"
    select="matches($override-existing-copy-to, 'yes|true|on|1', 'i')"
  />
  
  <!-- Expand topicrefs in relationship table cells such that
       references to topics that are not to a specific use of 
       the topic (i.e., not to a navigation topicref by key)
       are duplicated, once for each unique copy-to value 
       produced for that topic.
    -->
  <xsl:param name="expand-reltable-refs" as="xs:string" select="'no'"/>
  <xsl:param name="isExpandReltableRefs" as="xs:boolean" 
    select="matches($expand-reltable-refs, 'yes|true|on|1', 'i')"
  />
  
  <xsl:template match="/">
    
    <xsl:variable name="jobXml" as="document-node()"
      select="document($job.xml)"
    />
    <xsl:variable name="keydefXml" as="document-node()?"
      select="document('keydef.xml', $jobXml)"
    />
    
    <!-- Map of topics to their copy-to values. Also 
         captures the set of navigation topicrefs that
         points to a given topic.
      -->
    <xsl:variable name="topicToCopyToMap" as="element()">
      <xsl:apply-templates mode="makeCopyToMap"/>
    </xsl:variable>
    
    <!-- Do the result document processing: -->
    <xsl:apply-templates select="node()">
      <xsl:with-param name="topicToCopyToMap" as="element()" tunnel="yes"
        select="$topicToCopyToMap"
      />
    </xsl:apply-templates>
  </xsl:template>
  
  <!-- ==================================
       Mode makeCopyToMap 
       ================================== -->
  
  <xsl:template match="/*" mode="makeCopyToMap">
    <topicToCopyToMap>
      
    </topicToCopyToMap>
  </xsl:template>
  
  <!-- ==================================
       Default templates
       ================================== -->
  
  <xsl:template match="text() | processing-instruction() | comment() | @*">
    <xsl:sequence select="."/>
  </xsl:template>
  
  <xsl:template match="*">
    <xsl:copy>
      <xsl:apply-templates select="@*,node()"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>