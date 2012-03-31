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
    class PresentationLinkbase < Linkbase

      # Creates a PresentationLinkbase.
      #
      # linkbase_path::
      #   XBRL Presentation Linkbase source. Tries to load and parse presentation linkbase from path.
      #      
      # instance::
      #   Instance object
      #
      # def_linkbase::
      #   DefinitionLinkbase object      
      #
      # label_linkbase::
      #   optional parameter, LabelLinkbase object      
      def initialize(linkbase_path, instance, def_linkbase, label_linkbase=nil)
        super linkbase_path
        @instance=instance
        @def_linkbase=def_linkbase
        @label_linkbase=label_linkbase
        @pre_content_optimized=nil
      end

      def presentation(role=nil)
        presentations=[]

        if @pre_content_optimized.nil?
          pre_content=@linkbase_content["presentationLink"]

          @pre_content_optimized = []
          pre_content.each_with_index do |pre, index|
            next if pre["loc"].nil? || pre["presentationArc"].nil?
            pre["loc"].map! do |e|
              e["xlink:label"]="#{e['xlink:label']}_#{index}"
              e
            end

            pre["presentationArc"].map! do |e|
              e["xlink:from"]="#{e['xlink:from']}_#{index}"
              e["xlink:to"]="#{e['xlink:to']}_#{index}"
              e
            end
            selected=@pre_content_optimized.select {|pre_existing| pre_existing["xlink:role"]==pre["xlink:role"]}[0]
            if selected.nil?
              @pre_content_optimized << pre
            else
              pre["loc"].each do |current|
                matched_loc=nil
                selected["loc"].each do |existing|
                  if existing["xlink:href"]==current["xlink:href"]
                    matched_loc=current
                    pre["presentationArc"].each do |arc|
                      arc["xlink:from"] = existing["xlink:label"] if current["xlink:label"]==arc["xlink:from"]
                      arc["xlink:to"] = existing["xlink:label"] if current["xlink:label"]==arc["xlink:to"]
                    end
                    break
                  end
                end
                selected["loc"] << current if matched_loc.nil?
              end
              selected["presentationArc"] += pre["presentationArc"]
            end
          end
        end

        @pre_content_optimized.each do |pre|
          next unless pre["xlink:role"]==role unless role.nil?

          if pre["presentationArc"].nil?
            presentations << Presentation.new(@instance.entity_details, pre["xlink:title"], pre["xlink:role"], @role_map[pre["xlink:role"]])
          else
            definition=nil
            definition=@def_linkbase.definition(pre["xlink:role"]) unless @def_linkbase.nil?

            dimensions=[]
            dimensions = definition.dimension_domain_map.keys unless definition.nil?

            contexts_and_arcs=arcs(pre, dimensions)
            presentations << Presentation.new(@instance.entity_details, pre["xlink:title"], pre["xlink:role"], @role_map[pre["xlink:role"]], contexts_and_arcs["contexts"], contexts_and_arcs["arcs"], definition, @instance, dimensions)
          end
        end
        return presentations[0] unless role.nil?
        presentations
      end

      private
      def fetch_label(label_name, pref_label)
        pref_label="http://www.xbrl.org/2003/role/label" if pref_label.nil?
        label_obj=@label_linkbase.label(label_name, pref_label)
        label = label_obj.value unless label_obj.nil?
        return label
      end

      def arcs(pre, dimensions=[])
        locators={}
        pre["loc"].each do |loc|
          href = loc["xlink:href"]
          unless href.index("#").nil?
            locators[loc["xlink:label"]]= href[href.index("#")+1, href.length]
          else
            locators[loc["xlink:label"]]=href
          end
        end

        arc_map={}

        contexts = Set.new()

        pre["presentationArc"].each do |arc|
          from_label, to_label = nil, nil
          unless @label_linkbase.nil?
            to_label = fetch_label(locators[arc["xlink:to"]], arc["preferredLabel"])
            from_label = fetch_label(locators[arc["xlink:from"]], arc["preferredLabel"])
          end

          to = Presentation::PresentationArc.new(arc["xlink:to"], locators[arc["xlink:to"]], arc["xlink:arcrole"], arc["order"], arc["priority"], arc["use"], to_label)
          from = Presentation::PresentationArc.new(arc["xlink:from"], locators[arc["xlink:from"]], role=nil, order=nil, priority=nil, use=nil, label=from_label)

          to_item_name = locators[arc["xlink:to"]].gsub(/.*_/, "")
          from_item_name = locators[arc["xlink:from"]].gsub(/.*_/, "")

          to_item_map=item_map(@instance.item(to_item_name), dimensions)
          to.items=to_item_map.values
          contexts.merge(to_item_map.keys)

          from_item_map=item_map(@instance.item(from_item_name), dimensions)
          from.items=from_item_map.values
          contexts.merge(from_item_map.keys)

          if arc_map.has_key?(from)
            arc_map[from] << to
          else
            arc_map[from]=[to]
          end
        end
        return {"contexts" => contexts, "arcs" => Linkbase.build_relationship(arc_map)}
      end


      private
      def item_map(items, dimensions=[])
        item_map={}
        items.each do |item|
          if dimensions.size>0
            dims=item.context.dimensions
            item_map[item.context]=item if (dimensions-dims).size != dimensions.size && (not item.value.nil?)
          else
            item_map[item.context]=item unless item.context.has_explicit_dimensions? || item.value.nil?
          end
        end unless items.nil?
        item_map
      end

      public
      class Presentation < Linkbase::Link

        attr_reader :contexts, :definition, :instance, :dimensions, :entity_details

        def initialize(entity_details, title, role, href=nil, contexts=nil, arcs=nil, definition=nil, instance=nil, dimensions=[])
          super("Presentation", title, role, href, arcs)
          @entity_details=entity_details
          @contexts=contexts
          @definition=definition
          @instance=instance
          @dimensions=dimensions
        end

        def has_dimensions?
          return @dimensions.size>0
        end

        class PresentationArc < Linkbase::Link::Arc
          attr_reader :use

          def initialize(item_id, href, role=nil, order=nil, priority=nil, use=nil, label=nil)
            super item_id, href, role, order, priority, label
            @use=use
          end
        end
      end
    end
  end
end