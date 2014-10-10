<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:df="http://dita2indesign.org/dita/functions"
  xmlns:relpath="http://dita2indesign/functions/relpath"
  xmlns:local="urn:local-functions"
  exclude-result-prefixes="xs xd df relpath local"
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
  <xsl:import href="plugin:org.dita-community.common.xslt:xsl/dita-support-lib.xsl"/>
  
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
  
  <xsl:param name="debug" as="xs:string" select="'false'"/>
  <xsl:variable name="doDebug" as="xs:boolean"
    select="matches($debug, 'yes|true|on|1', 'i')"
  />
  
  <xsl:template match="/">
    
    <xsl:variable name="doDebug" as="xs:boolean" select="true() or $doDebug"/>
    
    <!-- Map of topics to their copy-to values. Also 
         captures the set of navigation topicrefs that
         points to a given topic.
      -->
    <xsl:variable name="topicToCopyToMap" as="element()">
      <xsl:apply-templates mode="makeCopyToMap">
        <xsl:with-param name="doDebug" as="xs:boolean" select="true() or $doDebug" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:variable>
    
    <xsl:if test="$doDebug">
      <xsl:result-document href="{relpath:newFile(relpath:getParent(document-uri(root(.))), 'topicToCopyToMap.xml')}"
        method="xml"
        indent="yes"
        >
        <xsl:sequence select="$topicToCopyToMap"/>
      </xsl:result-document>
    </xsl:if>
    
    <!-- Do the result document processing: -->
    <xsl:apply-templates select="node()">
      <xsl:with-param name="doDebug" as="xs:boolean" select="$doDebug" tunnel="yes"/>
      <xsl:with-param name="topicToCopyToMap" as="element()" tunnel="yes"
        select="$topicToCopyToMap"
      />      
    </xsl:apply-templates>
  </xsl:template>
  
  <!-- ==================================
       Mode makeCopyToMap 
       ================================== -->
  
  <xsl:template match="/*" mode="makeCopyToMap">
    <xsl:param name="doDebug" as="xs:boolean" select="false()" tunnel="yes"/>

    <topicToCopyToMap>
      <!-- Group topicrefs to topics by
           absolute URL of the topic referenced.
           
           Each map entry reflects one topic and lists
           all the topicrefs to it.
           
           The map resulting from mappull has both
           keyref and href values on topicrefs
           that only had keyrefs, so this should
           reliably include all topicrefs.
      
      -->
      <xsl:for-each-group 
        select=".//*[df:isTopicRef(.) and 
                        not(@processing-role = 'resource-only') and
                        not(ancestor::*[contains(@chunk, 'to-content')] and
                        @scope = 'local' and
                        (@format = 'dita' or @format = '') and
                        (@href != '' or @keyref != '')
                        )
                        ]"
        group-by="local:makeHrefAbsolute(.)"
        >     
        
        <xsl:if test="false()">
          <xsl:message> + [DEBUG] topicref: grouping-key="<xsl:sequence select="current-grouping-key()"/>", href="<xsl:sequence select="string(current-group()[1]/@href)"/>"
          </xsl:message>
        </xsl:if>
        <xsl:message> + [INFO] makeCopyToMap: Handling <xsl:value-of select="count(current-group())"/> topicrefs to topic <xsl:value-of
                               select="@href"/></xsl:message>
        <mapItem>
          <key><xsl:sequence select="current-grouping-key()"></xsl:sequence></key>
          <value>
            <!-- Value is a sequence of <copy-to> elements that relate topicrefs by generated ID
                 to the @copy-to value to use on that topicref.
              -->
            <xsl:apply-templates select="current-group()" mode="makeCopyToMap">
              <xsl:with-param name="topicrefsForTopic" as="element()+" tunnel="yes"
                select="current-group()"
              />
            </xsl:apply-templates>
          </value>
        </mapItem>
      </xsl:for-each-group>      
    </topicToCopyToMap>
  </xsl:template>
  
  <xsl:template mode="makeCopyToMap" match="*[df:class(., 'map/topicref')]">
    <xsl:param name="doDebug" as="xs:boolean" select="false()" tunnel="yes"/>
    <xsl:param name="topicrefsForTopic" as="element()+" tunnel="yes"/>
    
    <xsl:variable name="copytoValue">
      <xsl:apply-templates select="." mode="determineCopytoValue"/>
    </xsl:variable>
    <!-- If the copy-to value is empty, then don't create an item for this
         topicref.
      -->
    <xsl:if test="$copytoValue != ''">
      <copyTo 
        topicrefId="{generate-id(.)}" 
        copy-to="{normalize-space($copytoValue)}"
      />
    </xsl:if>
  </xsl:template>
  
  <!-- ==================================
       Mode  determineCopytoValue
       
       Handles topicrefs in the context of all
       topicrefs to a single topic. Determines
       the value to use for the @copy-to attribute
       of the topicref.
       
       Override templates in this mode to customize
       the copy-to values.
       ================================== -->
  
  <xsl:template mode="determineCopytoValue" match="*[df:class(., 'map/topicref')]">
    <xsl:param name="doDebug" as="xs:boolean" select="false()" tunnel="yes"/>
    
    <xsl:param name="topicrefsForTopic" as="element()+" tunnel="yes"/>
    
    <!-- Default implementation: Ensure result filename is unique by adding number
         to the base filename.
      -->
    
    <!-- In the resolved map the @href value is always present and is the relative
         path to the topic.
      -->
    <xsl:variable name="thisTopicref" as="element()" select="."/>
    <xsl:variable name="precedingTopicrefs" as="element()*"
      select="$topicrefsForTopic[. &lt;&lt; $thisTopicref]"
    />
    <xsl:if test="$doDebug">
      <!-- Put debug messages here -->
    </xsl:if>
    <xsl:choose>
      <xsl:when test="count($precedingTopicrefs) = 0">
        <xsl:message> + [INFO]     First reference and no @copy-to attribute. Not setting @copy-to.</xsl:message>

        <xsl:value-of select="''"/><!-- First topicref to the topic, no copy-to value -->
      </xsl:when>
      <xsl:otherwise>
        <!-- If there's already a copy-to on the topicref and it hasn't already been used, 
             use it, otherwise, construct a new value.
        -->
        <xsl:variable name="thisCopyTo" as="xs:string"
          select="if (@copy-to) then @copy-to else ''"
        />
        <xsl:choose>
          <xsl:when test="@copy-to != '' and 
                (not($precedingTopicrefs[@copy-to = $thisCopyTo][. &lt;&lt; $thisTopicref]))">
                  <xsl:message> + [INFO]     Using existing copy-to value "<xsl:value-of select="$thisCopyTo"/>".</xsl:message>

            <xsl:sequence select="string(@copy-to)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="ordinal" as="xs:integer" select="count($precedingTopicrefs) + 1"/>
            <xsl:variable name="countPicture" as="xs:string"
              select="if ($ordinal gt 999) then '0000'
                      else if ($ordinal gt 99) then '000'
                      else if ($ordinal gt 9) then '00'
                      else '00'
              "
            />
            <xsl:variable name="count"            
              as="xs:string"
              select="format-number($ordinal, $countPicture)"
            />
            <xsl:variable name="namePart" as="xs:string" 
              select="if ($thisCopyTo != '') 
                         then relpath:getNamePart($thisCopyTo)
                         else relpath:getNamePart(@href)" 
              
            />
            <xsl:variable name="ext" select="relpath:getExtension(@href)" as="xs:string"/>
            <xsl:variable name="dir" as="xs:string"
              select="if ($thisCopyTo != '') 
                         then relpath:getParent($thisCopyTo)
                         else relpath:getParent(@href)"
            />
            <xsl:variable name="copytoValue" select="relpath:newFile($dir, concat($namePart, '-', $count, '.', $ext))"/>
            <xsl:message> + [INFO]     Setting copy-to to "<xsl:value-of select="$copytoValue"/>".</xsl:message>
            <xsl:value-of select="$copytoValue"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
    
    
  </xsl:template>

  <!-- ==================================
       Default templates
       ================================== -->
  
  <xsl:template match="*[df:class(., 'map/topicref')]">
    <xsl:param name="topicToCopyToMap" as="element()" tunnel="yes"/>
    <xsl:variable name="copyToAtt" as="attribute()?">
      <xsl:variable name="topicrefID" as="xs:string" select="generate-id(.)" />
      <xsl:variable name="copyToItem" as="element()?"
        select="$topicToCopyToMap//copyTo[@topicrefId = $topicrefID]"
      />
      <xsl:sequence select="$copyToItem/@copy-to"/>
    </xsl:variable>
    <xsl:copy>
      <xsl:apply-templates select="@*, $copyToAtt, node()"/>
    </xsl:copy>
    
  </xsl:template>
  
  <xsl:template match="text() | processing-instruction() | comment() | @*">
    <xsl:sequence select="."/>
  </xsl:template>
  
  <xsl:template match="*">
    <xsl:copy>
      <xsl:apply-templates select="@*,node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- ==================================
       Local Functions
       ================================== -->
  
  <xsl:function name="local:makeHrefAbsolute" as="xs:string?">
    <!-- Given a topicref, make it's @href, if any, absolute.
      -->
    <xsl:param name="topicref" as="element()"/>
    <!-- For now ignoring the case where there is an absolute
         URL to a local-scope topic.
      -->
    <xsl:variable name="fullUrl" as="xs:string"
      select="relpath:newFile(relpath:getParent(base-uri($topicref)), $topicref/@href)"
    />
    <xsl:variable name="result"
      select="relpath:getAbsolutePath($fullUrl)"
    />
    <xsl:sequence select="$result"/>
  </xsl:function>
</xsl:stylesheet>