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
  # This class represents each unit in the XBRL instance file.
  # Look at {delaing with instance page on xbrlware wiki}[http://code.google.com/p/xbrlware/wiki/InstanceTaxonomy] for more details.
  class Unit
    include NSAware

    attr_reader :id, :measure

    def initialize(id, measure)
      @id = id
      @measure=measure
    end

    class Divide

      attr_reader :numerator, :denominator

      def initialize(numerator, denominator)
        @numerator=numerator
        @denominator=denominator
      end
    end
  end
end
