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
    class LabelLinkbase < Linkbase
      # Creates a LabelLinkbase.
      #
      # linkbase_path::
      #   XBRL Label Linkbase source. Tries to load and parse label linkbase from path.
      def initialize(linkbase_path)
        super linkbase_path
        @label_map={}
        parse_content
      end

      def label(item_name, label_role=nil, language=["en-US", "en"])
        return @label_map[item_name] if label_role.nil?
        return @label_map[item_name][label_role] unless @label_map[item_name].nil? if language.nil?
        return @label_map[item_name][label_role][language] unless @label_map[item_name].nil? || @label_map[item_name][label_role].nil? if language.is_a?(String)
        language.each do |lang|
          lab = @label_map[item_name][label_role][lang] unless @label_map[item_name].nil? || @label_map[item_name][label_role].nil?
          return lab unless lab.nil?
        end if language.is_a?(Array)
        return nil
      end

      def inspect
        self.to_s
      end

      def print(verbose_flag="q")
        str = StringIO.new
        @label_map.each do |key, value|
          str << key
          if verbose_flag=="v"
            value.each do |k, v|
              str << "\n" << "\t"
              str << " role [" << k << "]"
              str << "\n" << "\t\t"
              v.each do |lang, label|
                str << " lang [" << lang << "] label [" << label.value << "]"
              end
            end
          end
          str << "\n"
        end
        puts str.string
        return self.to_s
      end

      private
      def parse_content()

        label_links=@linkbase_content["labelLink"]
        label_links.each do |label_content|
          next if label_content["loc"].nil? || label_content["labelArc"].nil?
          loc_map=locator_map(label_content["loc"])
          arc_map=linkarc_map(label_content["labelArc"])

          labels=label_content["label"]
          labels.each do |label|
            l=Label.new(label["xlink:type"], label["xlink:role"], label["xlink:label"], label["xml:lang"], label["content"], @role_map[label["xlink:role"]])
            item_name=loc_map[arc_map[label["xlink:label"]]]
            if @label_map[item_name].nil?
              @label_map[item_name]={l.role => {l.lang => l}}
            else
              if @label_map[item_name][l.role].nil?
                @label_map[item_name][l.role] = {l.lang => l}
              else
                @label_map[item_name][l.role][l.lang] = l
              end
            end
          end
        end
      end

      def linkarc_map(arcs)
        arc_map={}
        arcs.each do |arc|
          arc_map[arc["xlink:to"]]=arc["xlink:from"]
        end
        arc_map
      end

      def locator_map(locators)
        locator_map={}
        locators.each do |loc|
          href = loc["xlink:href"]
          unless href.index("#").nil?
            locator_map[loc["xlink:label"]]=href[href.index("#")+1, href.length]
          else
            locator_map[loc["xlink:label"]]=href
          end
        end
        locator_map
      end

      public
      class Label

        attr_reader :type, :role, :href, :label, :lang, :value

        def initialize(type, role, label, lang, value, href=nil)
          @type=type
          @role=role
          @label=label
          @lang=lang
          @value=value
          @href=href
        end
      end

    end
  end
end