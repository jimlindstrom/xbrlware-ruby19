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

  # Class to deal with valid, well-formatted XBRl instance file.
  # This class provides methods to deal with instance file. 
  # Look at {delaing with instance page on xbrlware wiki}[http://code.google.com/p/xbrlware/wiki/InstanceTaxonomy] for more details.
  class Instance

    attr_reader :taxonomy

    # Creates an Instance.
    #
    # instance_str:: XBRL Instance source. Tries to load and parse instance file from the instance_str. This can be XBRL instance file from the file system or XBRL content string.
    #
    # taxonomy_filepath::
    #   optional parameter, XBRL Taxonomy source. Tries to load and parse taxonomy file from path.
    #   If this param is specified, taxonomy file in the instance document will be ignored
    #
    # Expects instance source is well-formatted and valid
    # Sometimes instance document contains large chunk of HTML content with new lines in-between,
    # which will cause parsing error. Hence any exceptions during instance source parsing, will trigger re-parsing of
    # the entire instnace file with new lines replaced.
    # Look at {delaing with instance page on xbrlware wiki}[http://code.google.com/p/xbrlware/wiki/InstanceTaxonomy] for details.
    def initialize(instance_str, taxonomy_filepath=nil)
      m=Benchmark.measure do
        begin
          @file_name=instance_str unless instance_str =~ /<.*?>/m
          @xbrl_content = XmlParser.xml_in(instance_str, {'ForceContent' => true})
        rescue Exception
          new_content=nil
          if instance_str =~ /<.*?>/m
            $LOG.warn "Supplied XBRL content is not well formed. Starting reparsing after removing new lines."
            new_content=instance_str.gsub("\n", "")
          else
            $LOG.warn "File ["+instance_str+"] is not well formed. Starting reparsing after removing new lines."
            new_content=File.open(instance_str).read.gsub("\n", "")
          end
          @xbrl_content = XmlParser.xml_in(new_content, {'ForceContent' => true}) unless new_content.nil?
        end
      end
      bm("Parsing [" + instance_str + "] took", m)

      # if taxonomy file is not supplied, get it from instance schema_ref
      if taxonomy_filepath.nil?
        taxonomy_file_location=File.dirname(instance_str)+File::Separator+schema_ref
        taxonomy_filepath = taxonomy_file_location if File.exist?(taxonomy_file_location) && (not File.directory?(taxonomy_file_location))
      end

      @taxonomy=Xbrlware::Taxonomy.new(taxonomy_filepath, self)
      @entity_details=Hash.new("UNKNOWN")
    end

    # Returns raw content of instance file in the form of Hash
    def raw
      @xbrl_content
    end

    # Returns schemaRef element of instance file. schemaRef holds path to taxonomy file for the instance file.
    def schema_ref
      base = @xbrl_content["schemaRef"][0]["xml:base"]
      href = @xbrl_content["schemaRef"][0]["xlink:href"]
      return base + href if base
      href
    end

    # Takes optional context_id as string and dimensions as array 
    #   Returns all contexts when context_id is nil
    #   Returns instance of Context object if context_id or dimensions is passed and matching context exist
    #   Returns nil if context_id or dimensions is passed and no matching context exist  
    def context(context_id=nil, dimensions=[])
      all_contexts= context_by_id(context_id)

      return all_contexts if dimensions.size==0

      contexts=[]

      all_contexts=[all_contexts] unless all_contexts.is_a?(Array)
      all_contexts.each do |ctx|
        next unless ctx.has_explicit_dimensions?(dimensions)
        contexts << ctx
      end

      return contexts[0] unless context_id.nil?
      contexts
    end

    # Returns contexts grouped by dimension as map. Map contains dimension as key and corresponding contexts as value
    def ctx_groupby_dim
      dim_group={}
      all_contexts= context
      all_contexts=[all_contexts] unless all_contexts.is_a?(Array)
      all_contexts.each do |ctx|
        ctx.explicit_dimensions.each do |dim|
          dim_group[dim] = [] if dim_group[dim].nil?
          dim_group[dim] << ctx
        end
      end
      dim_group
    end

    # Takes optional dimensions as array
    #   Returns contexts group by domain as map. Map contains domain as key and corresponding contexts as value
    def ctx_groupby_dom(dimensions=[])
      dom_group={}
      all_contexts= context(nil, dimensions)
      all_contexts=[all_contexts] unless all_contexts.is_a?(Array)
      all_contexts.each do |ctx|
        ctx.explicit_domains(dimensions).each do |dom|
          dom_group[dom] = [] if dom_group[dom].nil?
          dom_group[dom] << ctx
        end
      end
      dom_group
    end

    # Takes optional dimensions as array
    #   Returns contexts group by period as map. Map contains period as key and corresponding contexts as value
    def ctx_groupby_period(dimensions=[])
      period_group={}
      all_contexts= context(nil, dimensions)
      all_contexts=[all_contexts] unless all_contexts.is_a?(Array)
      all_contexts.each do |ctx|
        period_group[ctx.period] = [] if period_group[ctx.period].nil?
        period_group[ctx.period] << ctx
      end
      period_group
    end

    # Prints dimension -> domain -> context relationship for all contexts in the console. 
    def ctx_groupby_dim_dom_print
      group_dim=ctx_groupby_dim
      group_dim.keys.each do |dimension|
        puts " dimension :: " + dimension
        group_dom=ctx_groupby_dom(dimension)
        group_dom.keys.each do |domain|
          puts " \t domain :: " + domain
          group_dom[domain].each do |ctx|
            puts " \t\t ctx :: " + ctx.id
          end
        end
      end
    end

    def inspect
      self.to_s
    end

    private
    # Takes optional context_id
    #   Returns all contexts if context_id is nil
    #   Returns matching context as Context object if context_id is given and matching context found
    #   Returns nil if context_id is given and no matching context found    
    def context_by_id(context_id=nil)
      if context_id.nil?
        contexts=[]
        @xbrl_content["context"].each {|c| contexts << to_ctx_obj(c) }
        return contexts
      end

      ctx_content=nil
      @xbrl_content["context"].each { |ctx| ctx_content=ctx if ctx["id"]==context_id}
      $LOG.warn " unable to find context for id [" + context_id+"]" if ctx_content.nil?
      return nil if ctx_content.nil?
      return to_ctx_obj(ctx_content)

    end

    # Creates Context object from context content of XBRL instance file
    def to_ctx_obj (ctx_content)
      id=ctx_content["id"]

      entity_content = ctx_content["entity"][0]
      e = entity(entity_content)

      period_content = ctx_content["period"][0]
      p = period(period_content)

      s = scenario(ctx_content)
      _context = Context.new(id, e, p, s)
      _context.ns=ctx_content["nspace"]
      _context.nsp=ctx_content["nspace_prefix"]
      return _context
    end

    # Returns map  if period is duration. Map has key with name "start_date" and "end_date" 
    # Returns string if period is instant
    # Returns -1 if period is forever 
    def period(period_content)
      if period_content["startDate"] && period_content["endDate"]
        return {"start_date" => Date.parse(period_content["startDate"][0]["content"]), "end_date" => Date.parse(period_content["endDate"][0]["content"])}
      elsif period_content["instant"]
        return Date.parse(period_content["instant"][0]["content"])
      elsif period_content["forever"]
        return Context::PERIOD_FOREVER
      end
    end

    # Returns Entity object
    def entity(entity_content)
      entity_identifier = Identifier.new(entity_content["identifier"][0]["scheme"], entity_content["identifier"][0]["content"].strip!)

      entity_segment_content=entity_content["segment"]
      entity_segment=nil
      unless entity_segment_content.nil?
        entity_segment=entity_segment_content[0]
      end

      return Entity.new(entity_identifier, entity_segment)
    end

    # Returns scenario content
    def scenario(ctx_content)
      s=nil
      unless ctx_content["scenario"].nil?
        s = ctx_content["scenario"][0]
      end
      return s
    end

    public
    # Takes optional unit_id
    #   Returns all units if unit_id is nil
    #   Returns matching unit as Unit object if unit_id  is given and matching unit found
    #   Returns nil if unit_id is given and no matching unit found
    def unit(unit_id=nil)
      unit_content = @xbrl_content["unit"]
      return nil if unit_content.nil?

      units=[]

      l = lambda {|measure_list| measures=[]; measure_list.each { |measure| measures << measure["content"]}; return measures}
      unit_content.each do |unit|

        next unless unit_id.nil? || unit["id"].to_s == unit_id

        _unit=nil
        unless unit["measure"].nil?
          _unit = Unit.new(unit["id"], l.call(unit["measure"]))
        else
          divide_content = unit["divide"][0]

          numerator = l.call(divide_content["unitNumerator"][0]["measure"])
          denominator = l.call(divide_content["unitDenominator"][0]["measure"])

          divide=Unit::Divide.new(numerator, denominator)
          _unit = Unit.new(unit["id"], divide)
        end
        _unit.ns=unit["nspace"]
        _unit.nsp=unit["nspace_prefix"]
        units << _unit
      end
      return units[0] unless unit_id.nil?
      units
    end

    private
    def to_item_obj(item, name)
      context, unit, precision, decimals, _footnotes=nil

      context = context(item["contextRef"]) unless item["contextRef"].nil?
      value = item["content"]

      unit = unit(item["unitRef"]) unless item["unitRef"].nil?
      precision = item["precision"] unless item["precision"].nil?
      decimals = item["decimals"] unless item["decimals"].nil?

      _footnotes = footnotes(item["id"]) unless item["id"].nil?
      _item=Item.new(self, name, context, value, unit, precision, decimals, _footnotes)
      _item.ns=item["nspace"]
      _item.nsp=item["nspace_prefix"]
      _item.def=@taxonomy.definition(name)
      return _item
    end

    public
    def item_all

      return @item_all unless @item_all.nil?

      all_items = @xbrl_content
      return nil if all_items.nil?

      @item_all=[]

      all_items.each do |name, item_content|
        next unless item_content.is_a?(Array)
        next if item_content.size > 0 && item_content[0]["contextRef"].nil?
        @item_all = @item_all + item(name)
      end
      @item_all
    end

    def item_all_map
      items=item_all
      return nil if items.nil?

      items_hash={}

      items.each do |item|
        _name= item.name.upcase
        items_hash[_name] = [] unless items_hash.include?(_name)
        items_hash[_name] << item
      end
      items_hash
    end

    # Takes name and optional context_ref and unit_ref
    #  Returns array of Item for given name, context_ref and unit_ref
    #  Returns empty array if item is not found
    def item(name, context_ref=nil, unit_ref=nil)

      item_content = @xbrl_content[name]

      return [] if item_content.nil?

      items=[]

      item_content.each do |item|

        next unless context_ref.nil? || context_ref == item["contextRef"]
        next unless unit_ref.nil? || unit_ref == item["unitRef"]

        item = to_item_obj(item, name)
        items << item
      end
      items
    end

    # Takes item name
    #  Returns array of contexts for given item name
    #  Returns empty array if no item with given name found
    def context_for_item(item_name)
      contexts=[]
      items = item(item_name)
      items.each {|item| contexts << item.context}
      return contexts
    end


    # Takes item name and filter block
    #  Fetches item with name and invokes filter block with item context
    #  Returns matched items.
    def item_ctx_filter(name, &context_filter_block)
      items=item(name)
      return items if context_filter_block.nil?
      filtered_items=[]
      items.each do |item|
        filtered_items << item if yield(item.context)
      end
      filtered_items
    end

    public
    # Takes optional item id and language
    #  Every item in XBRL instance file may contain optional id element.
    #  Footnotes is associated with id of the item. Footnotes may be in different languages.
    #  Returns Map with lang as key and corresponding footnotes in array as value if item_id is givien
    #  Returns Map with item_id as key and another Map as value.
    #    Second map has lang as key and corresponding footnotes in array as value if item_id is givien
    #  Returns nil if no match found for item_it or footnotes not exist 
    def footnotes (item_id=nil, lang=nil)
      @item_footnote_map=nil
      raise " lang can't be passed when item id is nil" if item_id.nil? && (not lang.nil?)
      @item_footnote_map = compute_footnotes if @item_footnote_map.nil?
      return nil if @item_footnote_map.nil?
      return @item_footnote_map[item_id] if (not item_id.nil?) && lang.nil?
      return @item_footnote_map[item_id][lang] unless item_id.nil? || lang.nil?
      @item_footnote_map
    end

    def entity_details=(value)
      @entity_details.merge!(value) if value.is_a?(Hash)
    end

    def entity_details
      if @entity_details.size==0
        begin
          # Specific to US filing 
          e_name=item("EntityRegistrantName")[0]
          e_ci_key=item("EntityCentralIndexKey")[0]
          e_doc_type=item("DocumentType")[0]
          e_doc_end_type=item("DocumentPeriodEndDate")[0]

          fedate=item("CurrentFiscalYearEndDate")
          e_fiscal_end_date=fedate[0] unless fedate.nil?

          shares_outstanding = item("EntityCommonStockSharesOutstanding")
          e_common_shares_outstanding=shares_outstanding[0] unless shares_outstanding.nil?

          @entity_details["name"]=e_name.value unless e_name.nil?
          @entity_details["ci_key"]=e_ci_key.value unless e_ci_key.nil?
          @entity_details["doc_type"]=e_doc_type.value unless e_doc_type.nil?
          @entity_details["doc_end_date"]=e_doc_end_type.value unless e_doc_end_type.nil?
          @entity_details["fiscal_end_date"]=e_fiscal_end_date.value unless e_fiscal_end_date.nil?
          @entity_details["common_shares_outstanding"]=e_common_shares_outstanding.value unless e_common_shares_outstanding.nil?

          unless @file_name.nil?
            file_name=File.basename(@file_name)
            symbol=file_name.split("-")[0]
            symbol.upcase!

            @entity_details["symbol"]=symbol unless symbol.nil?
          end
        rescue Exception => e
          @entity_details
        end
      end
      @entity_details
    end

    private
    def compute_footnotes()
      return nil if @xbrl_content["footnoteLink"].nil?
      item_map={}
      @xbrl_content["footnoteLink"][0]["loc"].each do |loc|
        item_map[loc["xlink:label"]]=[] if item_map[loc["xlink:label"]].nil?
        item_map[loc["xlink:label"]] << loc["xlink:href"].split("#")[-1]
      end unless @xbrl_content["footnoteLink"][0]["loc"].nil?

      footnote_map = {}
      @xbrl_content["footnoteLink"][0]["footnote"].each do |fn|
        label=fn["xlink:label"]
        lang=fn["xml:lang"]
        content=fn["content"]

        footnote_map[label]={} if footnote_map[label].nil?
        footnote_map[label][lang]=content
      end unless @xbrl_content["footnoteLink"][0]["footnote"].nil?

      label_to_footnote_map = {}
      @xbrl_content["footnoteLink"][0]["footnoteArc"].each do |fn_arc|
        label_to_footnote_map[fn_arc["xlink:from"]] = [] if label_to_footnote_map[fn_arc["xlink:from"]].nil?
        label_to_footnote_map[fn_arc["xlink:from"]] << fn_arc["xlink:to"]
      end unless @xbrl_content["footnoteLink"][0]["footnoteArc"].nil?

      return nil if label_to_footnote_map.size==0

      item_footnote_map ={}
      label_to_footnote_map.each do |item_label, fn_labels|
        item_ids=item_map[item_label]
        item_ids.each do |item_id|
          item_footnote_map[item_id] = {} if item_footnote_map[item_id].nil?
          map=item_footnote_map[item_id]
          fn_labels.each do |fn_lab|
            fn=footnote_map[fn_lab]
            fn.each do |lang, content|
              map[lang]=[] if map[lang].nil?
              map[lang] << content
            end
          end unless fn_labels.nil?
        end unless item_ids.nil?
      end
      item_footnote_map
    end

  end
end