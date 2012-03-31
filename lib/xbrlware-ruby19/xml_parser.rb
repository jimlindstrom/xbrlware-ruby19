#!/usr/bin/ruby
#
# Author:: xbrlware@bitstat.com
#
# Copyright:: 2009, 2010 bitstat (http://www.bitstat.com). All Rights Reserved.
#
# License:: Licensed under the Apache License, Version 2.0 (the "License");
#           you may not use this file except in compliance with the License.
#           You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#           Unless required by applicable law or agreed to in writing, software
#           distributed under the License is distributed on an "AS IS" BASIS,
#           WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#           implied.
#           See the License for the specific language governing permissions and
#           limitations under the License.
#
module Xbrlware
# Method node_to_text, collapse of XmlSimple patched to bypass entity replacement.
# XmlSimple does entity replacement (XmlSimple depends on REXML which does entity replacement
# whenever node.valus is called. see http://www.germane-software.com/software/rexml/docs/tutorial.html under "Entity Replacement")
# to check an element is a text element or not. This is causing an issue, because XBRL document has large chuck of
# HTML content as part of their text node. These HTML contents are escaped (eg, '<' to &lt;), and XmlSimple treat them
# as entities tobe replaced with actual value. This was causing huge performance degradation. Hence two methods node_to_text
# and collapse of XmlSimple is patched to bypass entity replacement.
  class XmlParser < XmlSimple # :nodoc:

    # Converts a document node into a String.
    # If the node could not be converted into a String
    # for any reason, default will be returned.
    #
    # node::
    #   Document node to be converted.
    # default::
    #   Value to be returned, if node could not be converted.
    def node_to_text(node, default = nil)
      if node.instance_of?(REXML::Element)
        node.texts.map { |t| CGI::unescapeHTML(t.to_s) }.join('')
      elsif node.instance_of?(REXML::Attribute)
        node.value.nil? ? default : node.value.strip
      elsif node.instance_of?(REXML::Text)
        CGI::unescapeHTML(node.to_s).strip
      else
        default
      end
    end

    def XmlParser.xml_in(string = nil, options = nil)
      xml_parser = XmlParser.new
      xml_parser.xml_in(string, options)
    end

    private
    # Patch to xml-simple
    def has_text?(element)
      rv = element.get_text
      return (not rv.nil?)
    end

    # Converts the attributes array of a document node into a Hash.
    # Adds two attributes (nspace and nspace_prefix) to all elements.
    # if any attribute exist with above name, it will be overridden
    #
    # node::
    #   Document node to extract attributes from.
    def get_attributes(node)
      attributes = {}
      if @options['attrprefix']
        node.attributes.each { |n, v| attributes["@" + n] = v }
        attributes["@nspace"]=node.namespace
        attributes["@nspace_prefix"]=node.prefix
      else
        node.attributes.each { |n, v| attributes[n] = v }
        attributes["nspace"]=node.namespace
        attributes["nspace_prefix"]=node.prefix
      end
      attributes
    end

    public
    # Actually converts an XML document element into a data structure.
    #
    # element::
    #   The document element to be collapsed.
    def collapse(element)
      result = @options['noattr'] ? {} : get_attributes(element)

      if @options['normalisespace'] == 2
        result.each { |k, v| result[k] = normalise_space(v) }
      end

      if element.has_elements?
        element.each_element { |child|
          value = collapse(child)
          if empty(value) && (element.attributes.empty? || @options['noattr'])
            next if @options.has_key?('suppressempty') && @options['suppressempty'] == true
          end
          result = merge(result, child.name, value)
        }
        if has_mixed_content?(element)
          # normalisespace?
          content = element.texts.map { |x| x.to_s }
          content = content[0] if content.size == 1
          result[@options['contentkey']] = content
        end
      elsif has_text?(element) # i.e. it has only text.
        return collapse_text_node(result, element)
      end

      # Turn Arrays into Hashes if key fields present.
      count = fold_arrays(result)

      # Disintermediate grouped tags.
      if @options.has_key?('grouptags')
        result.each { |key, value|
          next unless (value.instance_of?(Hash) && (value.size == 1))
          child_key, child_value = value.to_a[0]
          if @options['grouptags'][key] == child_key
            result[key] = child_value
          end
        }
      end

      # Fold Hashes containing a single anonymous Array up into just the Array.
      if count == 1
        anonymoustag = @options['anonymoustag']
        if result.has_key?(anonymoustag) && result[anonymoustag].instance_of?(Array)
          return result[anonymoustag]
        end
      end

      if result.empty? && @options.has_key?('suppressempty')
        return @options['suppressempty'] == '' ? '' : nil
      end

      result
    end

  end
end