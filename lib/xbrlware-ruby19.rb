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
require 'xmlsimple'
require 'rexml/document'
require 'rexml/streamlistener'

require 'date'
require 'bigdecimal'
require 'erb'
require 'set'
require "stringio"
require 'cgi'

require 'xbrlware-ruby19/version'
require 'xbrlware-ruby19/float_patch'
require 'xbrlware-ruby19/cgi_patch'
require 'xbrlware-ruby19/meta_util'
require 'xbrlware-ruby19/hash_util'
require 'xbrlware-ruby19/date_util'
require 'xbrlware-ruby19/xml_parser'

require 'xbrlware-ruby19/constants'
require 'xbrlware-ruby19/util'

require 'xbrlware-ruby19/taxonomies/us_gaap_taxonomy_20090131'

module Xbrlware; module Taxonomies
autoload :IFRS20090401, 'xbrlware-ruby19/taxonomies/ifrs_taxonomy_20090401'
end; end;

require 'xbrlware-ruby19/taxonomy'

require 'xbrlware-ruby19/ns_aware'
require 'xbrlware-ruby19/context'
require 'xbrlware-ruby19/instance'
require 'xbrlware-ruby19/unit'
require 'xbrlware-ruby19/item'

require 'xbrlware-ruby19/linkbase/linkbase'
require 'xbrlware-ruby19/linkbase/label_linkbase'
require 'xbrlware-ruby19/linkbase/calculation_linkbase'
require 'xbrlware-ruby19/linkbase/definition_linkbase'
require 'xbrlware-ruby19/linkbase/presentation_linkbase'

require 'xbrlware-ruby19/edgar_util'
require 'xbrlware-ruby19/edgar_data_downloader'

require 'logger'
require 'benchmark'

ENV["TAXO_NAME"]="US-GAAP"
ENV["TAXO_VER"]="20090131"

$LOG = Logger.new($stdout)
$LOG.level = Logger::INFO

def bm(title, measure) # :nodoc:
  $LOG.debug title +" [ u :"+measure.utime.to_s+", s :"+measure.stime.to_s+", t :"+measure.total.to_s+", r :"+measure.real.to_s+"]"    
end
