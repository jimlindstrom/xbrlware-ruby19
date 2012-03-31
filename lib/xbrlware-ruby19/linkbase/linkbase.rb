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

    class Linkbase
      # Creates a Linkbase.
      #
      # linkbase_path::
      #   XBRL Linkbase source. Tries to load and parse linkbase from path.
      #
      def initialize(linkbase_path)
        m=Benchmark.measure do
          begin
            @linkbase_content = XmlParser.xml_in(linkbase_path, {'ForceContent' => true})
          rescue Exception
            $LOG.warn "File ["+linkbase_path+"] is not well formed. Starting reparsing after removing new lines."
            @linkbase_content = XmlParser.xml_in(File.open(linkbase_path).read.gsub("\n", ""), {'ForceContent' => true})
          end
        end
        bm("Parsing [" + linkbase_path + "] took", m)

        #Populate role map
        role_map()
      end

      private
      def role_map
        @role_map={}
        @linkbase_content["roleRef"].each do |role_ref|
          href = role_ref["xlink:href"]
          unless href.index("#").nil?
            @role_map[role_ref["roleURI"]]= href[href.index("#")+1, href.length]
          else
            @role_map[role_ref["roleURI"]]=href
          end
        end unless @linkbase_content["roleRef"].nil?
      end

      public

      def inspect
        self.to_s
      end

      def self.wireup_relationship(map, parent, child) # :nodoc:

        if child.is_a?(Array)
          child.each do |c|
            wireup_relationship(map, parent, c)
          end
          return
        end

        child.parent=parent
        parent.children.add(child)
        return unless map.has_key?(child)

        # map contains different instance (that equals to child) as key.
        # Delete the key, reinsert the proper instance as key  
        children_of_child=map[child]
        map.delete(child)
        map[child]=children_of_child
        wireup_relationship(map, child, map[child])
      end

      def self.build_relationship(map) # :nodoc:
        map.each do |key, value|
          wireup_relationship(map, key, value)
        end
        root_elements=map.keys.select { |key| key.parent.nil?}
        root_elements.each {|root_element| sort_by_order(root_element)}
        return root_elements
      end

      def self.sort_by_order(element) # :nodoc:
        return if element.children.nil?
        element.children=element.children.sort_by {|e| (e.respond_to?(:order) && e.order) || "0"}
        element.children.each do |child|
          sort_by_order(child)
        end
      end

      class Link

        attr_reader :link_type, :title, :role, :href, :arcs

        def initialize(link_type, title, role, href, arcs=nil)
          @link_type=link_type
          @role = role
          @href = href

          @title=title unless title.nil?
          @title=role.split("/")[-1] if title.nil?
          @title=@title.split(/(?=[A-Z])/).join(' ')
          @title.gsub!(/_/, " ")
          @title.gsub!(/[ ]+/, " ")

          @arcs = arcs
        end

        private
        def print_arc_hierarchy(verbose_flag="q", arcs=@arcs, indent=0)
          arcs.each do |arc|
            str=" " * indent + arc.item_name + "("+(arc.label if arc.respond_to?(:label)).to_s+")"
            if verbose_flag=="v"
              str +=" label [" +(arc.label if arc.respond_to?(:label)).to_s+"], role ["+arc.role.to_s+"]"
            end
            str += " order ["+arc.order.to_s+"]"
            puts str
            print_arc_hierarchy(verbose_flag, arc.children, indent+1) if arc.children
          end unless arcs.nil?
        end

        public
        def inspect
          self.to_s
        end

        def print(verbose_flag="q")
          puts " title ["+title+"] role ["+role+"]"
          print_arc_hierarchy(verbose_flag)
          return self.to_s
        end

        class Arc
          attr_reader :item_id, :item_name, :role, :label, :href, :order, :priority
          attr_accessor :items, :children, :parent

          def initialize(item_id, href, role=nil, order=nil, priority=nil, label=nil)
            @item_id=item_id
            @item_name = @item_id[0, (@item_id.rindex("_")==nil ? @item_id.size: @item_id.rindex("_"))]
            @href=href
            @role=role
            @order=order.to_i
            @priority=priority.to_i
            if label.nil?
              if href.nil?
                dash_index=item_id.index("_")
                dash_index=dash_index.nil? ? 0 :(dash_index+1)
                label=item_id[dash_index, item_id.length]
              else
                label=href[href.index("#")+1, href.length] unless href.index("#").nil?
                label=href if href.index("#").nil?
                unless label.index("_").nil?
                  dash_index=label.index("_")
                  label=label[dash_index+1, label.length]
                end
              end
            end
            @label=label
            @children=Set.new()
          end

          def has_children?
            @children.size>0
          end

          def eql?(o)
            o.is_a?(Arc) && @item_id == o.item_id
          end

          def hash
            @item_id.hash
          end

          def inspect
            self.to_s
          end
        end
      end

    end

  end
end