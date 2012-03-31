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
  module Linkbase
    class DefinitionLinkbase < Linkbase

      @@constants = {"primaryItem-hypercube" => "http://xbrl.org/int/dim/arcrole/all",
                     "hypercube-dimension" => "http://xbrl.org/int/dim/arcrole/hypercube-dimension",
                     "dimension-domain" => "http://xbrl.org/int/dim/arcrole/dimension-domain",
                     "domain-member" => "http://xbrl.org/int/dim/arcrole/domain-member"}

      # Creates a DefinitionLinkbase.
      #
      # linkbase_path::
      #   XBRL Definition Linkbase source. Tries to load and parse definition linkbase from path.
      #
      # label_linkbase::
      #   optional parameter, takes LabelLinkbase object      
      def initialize(linkbase_path, label_linkbase=nil)
        super linkbase_path
        @label_linkbase=label_linkbase
        @def_content_optimized=nil
      end

      def definition(role=nil)

        definitions=[]

        if @def_content_optimized.nil?
          def_content=@linkbase_content["definitionLink"]

          @def_content_optimized = []
          def_content.each_with_index do |_def, index|
            next if _def["loc"].nil? || _def["definitionArc"].nil?
            _def["loc"].map! do |e|
              e["xlink:label"]="#{e['xlink:label']}_#{index}"
              e
            end

            _def["definitionArc"].map! do |e|
              e["xlink:from"]="#{e['xlink:from']}_#{index}"
              e["xlink:to"]="#{e['xlink:to']}_#{index}"
              e
            end
            selected=@def_content_optimized.select {|def_existing| def_existing["xlink:role"]==_def["xlink:role"]}[0]
            if selected.nil?
              @def_content_optimized << _def
            else
              _def["loc"].each do |current|
                matched_loc=nil
                selected["loc"].each do |existing|
                  if existing["xlink:href"]==current["xlink:href"]
                    matched_loc=current
                    _def["definitionArc"].each do |arc|
                      arc["xlink:from"] = existing["xlink:label"] if current["xlink:label"]==arc["xlink:from"]
                      arc["xlink:to"] = existing["xlink:label"] if current["xlink:label"]==arc["xlink:to"]
                    end
                    break
                  end
                end
                selected["loc"] << current if matched_loc.nil?
              end
              selected["definitionArc"] += _def["definitionArc"]
            end
          end
        end

        @def_content_optimized.each do |def_|

          next unless def_["xlink:role"]==role unless role.nil?

          if def_["definitionArc"].nil?
            definitions << Definition.new(def_["xlink:title"], def_["xlink:role"], @role_map[def_["xlink:role"]])
          else
            arcs=arcs(def_)
            definitions << Definition.new(def_["xlink:title"], def_["xlink:role"], @role_map[def_["xlink:role"]], primary_items(arcs))
          end
        end
        return definitions[0] unless role.nil?
        definitions
      end

      private
      def primary_items(arcs)
        items=Set.new
        arcs.each do |arc|
          arc.children.each do |child|
            if child.role==@@constants["primaryItem-hypercube"]
              items << arc
              break
            end
          end if arc.has_children?
        end

        items.each do |primary_item|

          hypercubes=[]
          primary_item.children.each do |p_child|
            hypercubes << p_child if p_child.role==@@constants["primaryItem-hypercube"]
          end if primary_item.has_children?
          primary_item.children = hypercubes
          MetaUtil::introduce_instance_alias(primary_item, "hypercubes", "children")

          primary_item.hypercubes.each do |hypercube|
            dimensions=[]
            hypercube.children.each do |h_child|
              dimensions << h_child if h_child.role==@@constants["hypercube-dimension"]
            end if hypercube.has_children?
            hypercube.children=dimensions
            MetaUtil::introduce_instance_alias(hypercube, "dimensions", "children")

            hypercube.dimensions.each do |dimension|
              domains=[]
              dimension.children.each do |di_child|
                domains << di_child if di_child.role==@@constants["dimension-domain"]
              end if dimension.has_children?
              dimension.children=domains
              MetaUtil::introduce_instance_alias(dimension, "domains", "children")

              dimension.domains.each do |domain|
                members=[]
                domain.children.each do |do_child|
                  members << do_child if do_child.role==@@constants["domain-member"]
                end if domain.has_children?
                MetaUtil::introduce_instance_alias(domain, "members", "children")
                MetaUtil::introduce_instance_writer(domain, "members", "children")
              end
            end
          end
        end
        items
      end

      private
      def arcs(def_)

        locators={}
        def_["loc"].each do |loc|
          href = loc["xlink:href"]
          unless href.index("#").nil?
            locators[loc["xlink:label"]]= href[href.index("#")+1, href.length]
          else
            locators[loc["xlink:label"]]=href
          end
        end

        arc_map={}

        def_["definitionArc"].each do |arc|

          to_label = nil
          unless @label_linkbase.nil?
            to_label_obj=@label_linkbase.label(locators[arc["xlink:to"]], arc["preferredLabel"]) unless arc["preferredLabel"].nil?
            to_label_obj=@label_linkbase.label(locators[arc["xlink:to"]], "http://www.xbrl.org/2003/role/label") if arc["preferredLabel"].nil?
            to_label = to_label_obj.value unless to_label_obj.nil?
          end

          to = Definition::DefinitionArc.new(arc["xlink:to"], locators[arc["xlink:to"]], arc["xlink:arcrole"], arc["order"], arc["priority"], to_label, arc["xbrldt:contextElement"])
          from = Definition::DefinitionArc.new(arc["xlink:from"], locators[arc["xlink:from"]])

          if arc_map.has_key?(from)
            arc_map[from] << to
          else
            arc_map[from]=[to]
          end
        end

        return Linkbase.build_relationship(arc_map)
      end

      public
      class Definition < Linkbase::Link

        attr_reader :primary_items

        def initialize(title, role, href=nil, primary_items=nil)
          super("Definition", title, role, href, primary_items)
          @primary_items=primary_items
        end

        def dimension_domain_map
          dim_dom_map={}
          @primary_items.each do |primary_item|
            primary_item.hypercubes.each do |hypercube|
              hypercube.dimensions.each do |dimension|
                domains=[]
                dimension.domains.each do |domain|
                  domains << domain.href.sub("_", ":")
                end
                dim_dom_map[dimension.href.sub("_", ":")]=domains if domains.size > 0
              end
            end
          end unless @primary_items.nil?
          dim_dom_map
        end

        class DefinitionArc < Linkbase::Link::Arc
          attr_reader :ctx_element

          def initialize(item_id, href, role=nil, order=nil, priority=nil, label=nil, ctx_element=nil)
            super item_id, href, role, order, priority, label
            @ctx_element=ctx_element
          end
        end
      end

    end
  end
end