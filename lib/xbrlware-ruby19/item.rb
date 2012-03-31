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

  # This class represents each item in the XBRL instance file.
  #  Taxonomy definition of a item can be retrieved using def or meta methods.
  # Look at {delaing with instance page on xbrlware wiki}[http://code.google.com/p/xbrlware/wiki/InstanceTaxonomy] for more details.
  class Item
    include NSAware

    attr_reader :name, :context, :unit, :precision, :decimals, :footnotes
    attr_accessor :ins, :def

    # Constructs item
    # value is normalized based on precision and decimals passed as per XBRL specification
    def initialize(instance, name, context, value, unit=nil, precision=nil, decimals=nil, footnotes=nil)
      @ins=instance
      @name=name
      @context = context
      @precision=precision
      @decimals=decimals
      @footnotes=footnotes
      @value = ItemValue.new(value, precision, decimals).value
      @unit = unit
    end

    def value
      return yield(@value) if block_given?
      @value
    end

    def is_value_numeric?
      @value.to_i.to_s == @value || @value.to_f.to_s == @value
    end

    alias_method :meta, :def

    def balance
      _balance=meta["xbrli:balance"] unless meta.nil?
      _balance.nil? ? "" : _balance
    end

    class ItemValue # :nodoc:

      attr_reader  :item_value

      def initialize(item_value, precision=nil, decimals=nil)
        @item_value=item_value
        @precision=precision
        @decimals=decimals
      end

      def value()
        return precision() unless @precision.nil?
        return decimals() unless @decimals.nil?
        return @item_value
      end

      # returns BigDecimal float representation as String
      def precision()
        return @item_value if @precision=="INF"

        precision_i=@precision.to_i
        new_value=BigDecimal(@item_value)

        is_value_integer = new_value==@item_value.to_i


        return to_precision_from_integer(@item_value.to_i, precision_i) if is_value_integer

        index_of_dot = new_value.abs.to_s("F").index(".")

        # When mod value is greater than 1 and float number 
        if new_value.abs > 1
          #Precision is less than number of digits before decimal
          return to_precision_from_integer(new_value.to_i, precision_i) if precision_i <= index_of_dot

          #Precision is greater than number of digits before decimal
          return new_value.round(precision_i-index_of_dot).to_s("F")
        else
          new_value_s = new_value.abs.to_s("F")
          no_of_zeroes = new_value_s.split(/[1-9].*/).join.length - new_value_s.index(".")-1
          return new_value.round(no_of_zeroes + precision_i).to_s("F")
        end
      end

      # returns BigDecimal float representation as String
      def decimals
        return @item_value if @decimals=="INF"
        return BigDecimal(@item_value).round(@decimals.to_i).to_s("F")
      end

      private
      def to_precision_from_integer(new_value, precision_i)
        factor=10 **(new_value.abs.to_s.length - precision_i)
        return to_big_decimal_float_str(((BigDecimal(new_value.to_s) / factor).to_i * factor).to_s)
      end

      def to_big_decimal_float_str(value)
        return BigDecimal(value).to_s("F")
      end

    end
  end

end