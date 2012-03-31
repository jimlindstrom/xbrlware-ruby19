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

  # Class to deal with taxonomy of instance file.
  class Taxonomy

    attr_accessor :ignore_lablb, :ignore_deflb, :ignore_prelb, :ignore_callb 

    # Creates a Taxonomy.
    #
    # taxonomy_path:: Instance taxonomy source path.
    # instance:: Instance object  
    def initialize(taxonomy_path, instance)
      @instance=instance
      @taxonomy_content=nil

      @taxonomy_file_basedir=nil
      unless taxonomy_path.nil?
        m=Benchmark.measure do
          begin
            @taxonomy_content=XmlParser.xml_in(taxonomy_path, {'ForceContent' => true})
          rescue Exception
            @taxonomy_content=XmlParser.xml_in(File.open(taxonomy_path).read.gsub("\n", ""), {'ForceContent' => true})
          end
          @taxonomy_file_basedir=File.dirname(taxonomy_path)+File::Separator
        end
        bm("Parsing [" + taxonomy_path + "] took", m)
      end

      @taxonomy_def_instance=TaxonomyDefintion.new
      @taxonomy_content["element"].each do |element|
        MetaUtil::introduce_instance_var(@taxonomy_def_instance, element["name"].gsub(/[^a-zA-Z0-9_]/, "_"), element)
      end unless @taxonomy_content.nil? || @taxonomy_content["element"].nil?

      @lablb, @deflb, @prelb, @callb=nil
    end

    # gets taxonomy definition 
    def definition(name)
      @taxonomy_def_instance.send(name.gsub(/[^a-zA-Z0-9_]/, "_"))
    end

    # initialize and returns label linkbase 
    def lablb(file_path=nil)
      return nil if ignore_lablb
      file_path=linkbase_href(Xbrlware::LBConstants::LABEL) if file_path.nil? && @lablb.nil?
      return @lablb if file_path.nil?
      $LOG.warn(" Label linkbase already initialized. Ignoring " + file_path) unless file_path.nil? || @lablb.nil?
      @lablb = Xbrlware::Linkbase::LabelLinkbase.new(file_path) if @lablb.nil? && File.exist?(file_path)  
      @lablb
    end

    # initialize and returns definition linkbase
    def deflb(file_path=nil)
      return nil if ignore_deflb
      file_path=linkbase_href(Xbrlware::LBConstants::DEFINITION) if file_path.nil? && @deflb.nil?
      return @deflb if file_path.nil?
      $LOG.warn(" Definition linkbase already initialized. Ignoring " + file_path) unless file_path.nil? || @deflb.nil?
      @deflb = Xbrlware::Linkbase::DefinitionLinkbase.new(file_path, lablb()) if @deflb.nil? && File.exist?(file_path)
      @deflb
    end

    # initialize and returns presentation linkbase
    def prelb(file_path=nil)
      return nil if ignore_prelb
      file_path=linkbase_href(Xbrlware::LBConstants::PRESENTATION) if file_path.nil? && @prelb.nil?
      return @prelb if file_path.nil?
      $LOG.warn(" Presentation linkbase already initialized. Ignoring " + file_path) unless file_path.nil? || @prelb.nil?
      @prelb = Xbrlware::Linkbase::PresentationLinkbase.new(file_path, @instance, deflb, lablb) if @prelb.nil? && File.exist?(file_path)
      @prelb
    end

    # initialize and returns calculation linkbase
    def callb(file_path=nil)
      return nil if ignore_callb
      file_path=linkbase_href(Xbrlware::LBConstants::CALCULATION) if file_path.nil? && @callb.nil?
      return @callb if file_path.nil?
      $LOG.warn(" Calculation linkbase already initialized. Ignoring " + file_path) unless file_path.nil? || @callb.nil?
      @callb = Xbrlware::Linkbase::CalculationLinkbase.new(file_path, @instance, lablb) if @callb.nil? && File.exist?(file_path)
      @callb
    end

    # initialize all linkbases
    def init_all_lb(cal_file_path=nil, pre_file_path=nil, lab_file_path=nil, def_file_path=nil)
      @lablb, @deflb, @prelb, @callb=nil
      lablb(lab_file_path)
      deflb(def_file_path)
      prelb(pre_file_path)
      callb(cal_file_path)
      return
    end

    private
    def linkbase_href(linkbase)
      begin
        linkbase_refs=@taxonomy_content["annotation"][0]["appinfo"][0]["linkbaseRef"]
        linkbase_refs.each do |ref|
          if ref["xlink:role"]==linkbase
            return @taxonomy_file_basedir + ref["xlink:href"] if ref["xml:base"].nil?
            return @taxonomy_file_basedir + ref["xml:base"] + ref["xlink:href"]
          end
        end
      rescue Exception => e
      end
      nil
    end

  end

  class TaxonomyDefintion

    def initialize
      taxonomy_module=ENV["TAXO_NAME"].to_s.sub("-", "") + ENV["TAXO_VER"].to_s
      if eval("defined?(Taxonomies::#{taxonomy_module}) == 'constant' and Taxonomies::#{taxonomy_module}.class == Module")
        eval("self.extend Taxonomies::#{taxonomy_module}")
      else
        $LOG.warn("No taxonomy found for name ["+ENV["TAXO_NAME"].to_s+"] and version ["+ENV["TAXO_VER"].to_s+"]")
      end
    end

    def method_missing(m, *args)
      nil
    end
  end
end