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
  # This class represents each context in the XBRL instance file.
  # Look at {delaing with instance page on xbrlware wiki}[http://code.google.com/p/xbrlware/wiki/InstanceTaxonomy] for more details.
  class Context
    include NSAware
    
    attr_reader :id, :entity, :period, :scenario
    PERIOD_FOREVER = -1

    class Period
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def to_s
        @value.to_s
      end

      def eql?(o)
        o.is_a?(Period) && @value == o.value
      end

      def hash
        @value.hash
      end

      def is_instant?
        @value.is_a?(Date)
      end

      def is_duration?
        @value.is_a?(Hash)
      end

      def is_forever?
        @value.is_a?(Fixnum)
      end
    end

    def initialize(id, entity, period, scenario=nil)
      @id = id
      @entity = entity
      @period = Period.new(period)
      @scenario=scenario
    end

    def has_scenario?
      (not @scenario.nil?)
    end

    def to_s
      "Id [" + id + "], Entity { " + @entity.to_s + " },  period ["+period.to_s+"]"+ (",  scenario ["+scenario+"]" unless scenario.nil?).to_s
    end

    def eql?(o)
      o.is_a?(Context) && @id == o.id
    end

    def hash
      @id.hash
    end

    def has_explicit_dimensions?(dimensions=[])
      return @entity.has_explicit_dimensions?(dimensions) unless @entity.nil?
      false
    end

    alias_method :has_dimensions?, :has_explicit_dimensions?

    def explicit_dimensions
      return @entity.explicit_dimensions
    end

    alias_method :dimensions, :explicit_dimensions

    def explicit_domains(dimensions=[])
      return @entity.explicit_domains(dimensions)
    end

    alias_method :domains, :explicit_domains

    def explicit_dimensions_domains
      return @entity.explicit_dimensions_domains
    end

    alias_method :dimensions_domains, :explicit_dimensions_domains

  end

  class Entity
    attr_reader :identifier, :segment

    def initialize(identifier, segment=nil)
      @identifier = identifier
      @segment = segment
    end

    def has_segment?
      (not @segment.nil?)
    end

    def to_s
      "Identifier { " + @identifier.to_s + " } " + (", segment [" + segment.to_s + "]" unless segment.nil?).to_s
    end

    def has_explicit_dimensions?(dimensions=[])
      dimensions_set=Set.new
      dimensions_set.merge(dimensions)
      unless @segment.nil? || @segment["explicitMember"].nil?

        return true if dimensions.size==0

        dim = Set.new
        @segment["explicitMember"].each do |member|
          dim << member["dimension"]
        end
        return dim.superset?(dimensions_set)
      end

      return false
    end

    def explicit_dimensions
      dim = Set.new
      unless @segment.nil? || @segment["explicitMember"].nil?
        @segment["explicitMember"].each do |member|
          dim << member["dimension"]
        end
      end
      return dim.to_a
    end

    def explicit_domains(dimensions=[])
      dom = Set.new
      if has_explicit_dimensions?(dimensions)
        @segment["explicitMember"].each do |member|
          dimensions=explicit_dimensions if dimensions.size==0
          dimensions.each do |dim|
            next unless dim==member["dimension"]
            dom << member["content"]
          end
        end
      end
      return dom.to_a
    end

    def explicit_dimensions_domains
      dim_dom={}
      if has_explicit_dimensions?
        @segment["explicitMember"].each do |member|
          dim_dom[member["dimension"]]=[] if dim_dom[member["dimension"]].nil?
          dim_dom[member["dimension"]] << member["content"]
        end
      end
      return dim_dom
    end

  end

  class Identifier
    attr_reader :value, :scheme

    def initialize(scheme, value)
      @scheme = scheme
      @value = value
    end

    def to_s
      "schema [" + @scheme.to_s + "], value [" + @value.to_s + "]"
    end
  end
end