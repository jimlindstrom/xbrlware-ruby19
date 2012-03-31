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
  module DateUtil # :nodoc:
    def self.stringify_date (date)
      return "" if date.nil?
      begin
        _date=Date.parse(date) if date.is_a?(String)
        _date=date if date.is_a?(Date)
        m=Date::ABBR_MONTHNAMES[_date.month]
        m + " " + _date.day.to_s + ", " + _date.year.to_s
      rescue Exception => e
        ""
      end
    end

    def self.months_between(date1=Date.today, date2=Date.today)
      begin
        date1=Date.parse(date1) if date1.is_a?(String)
        date2=Date.parse(date2) if date2.is_a?(String)
        (date1 > date2) ? (recent_date, past_date = date1, date2) : (recent_date, past_date = date2, date1)
        (recent_date.year - past_date.year) * 12 + (recent_date.month - past_date.month) + 1
      rescue Exception => e
        0
      end
    end
  end
end