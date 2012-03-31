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
module Edgar
  
  # This class defines method to download XBRL files from SEC's XBRL RSS Feed.  
  # See {report generation xbrlware wiki}[http://code.google.com/p/xbrlware/wiki/ReportGeneration] for how to use this class.  
  class RSSFeedDownloader
    include FileUtil

    attr_reader :content

    def initialize(sec_edgar_rss_file=nil)
      sec_edgar_rss_file ||= "http://www.sec.gov/Archives/edgar/usgaap.rss.xml"
      @content = XmlSimple.xml_in(open(sec_edgar_rss_file).read, {'ForceContent' => true})
    end

    # Takes limit (how many entities to download), download_to (where to download)
    #  default value for limit is 100
    #  default value for download_to is current_dir + "/edgar_data" 
    def download(limit=100, download_to=File.expand_path(".")+File::SEPARATOR+"edgar_data")
      items=@content["channel"][0]["item"]
      items.each_with_index do |item, index|
        break if index==limit
        files=get_xbrl_files(item)
        download_to += File::SEPARATOR unless download_to.end_with?(File::SEPARATOR)
        data_dir=download_to
        data_dir=data_dir+File::SEPARATOR+item["xbrlFiling"][0]["cikNumber"][0]["content"]
        data_dir=data_dir+File::SEPARATOR+item["xbrlFiling"][0]["accessionNumber"][0]["content"]
        mkdir(data_dir)
        files.each do |file|
          file_content=open(file["edgar:url"]).read
          dump_to_file(data_dir+File::SEPARATOR+file["edgar:file"], file_content)
        end
      end
    end

    def print_stat # :nodoc:
      i_url=""
      i_size=0
      title=""
      items=@content["channel"][0]["item"]
      items.each do |item|
        files=get_xbrl_files(item)
        files.each do |file|
          if file["type"]=="EX-101.INS" && (i_size==0 || file["size"].to_i < i_size)
            i_size = file["edgar:size"].to_i
            i_url = file["edgar:url"]
            title = item["edgar:title"]
          end
        end
      end
      puts ""
      puts " Smallest Instance File " + i_url 
    end

    private
    # Gets url that end with xml and xsd 
    def get_xbrl_files(item)
      xbrl_files=item["xbrlFiling"][0]["xbrlFiles"][0]["xbrlFile"]
      return xbrl_files.select {|e| e["edgar:url"].end_with?("xml") || e["edgar:url"].end_with?("xsd")}
    end

  end

  # This class defines method to download XBRL files from SEC's EDGAR filling url.
  # See {report generation xbrlware wiki}[http://code.google.com/p/xbrlware/wiki/ReportGeneration] for how to use this class.
  class HTMLFeedDownloader
    include REXML::StreamListener
    include FileUtil

    attr_reader :links

    # Takes url and download_to (where to download)
    #  default value for download_to is current_dir    
    def download(url, download_to=File.expand_path(".")+File::SEPARATOR)
      $LOG.info " Starting download of fillings from SEC url ["+url+"]"
      files=[]
      content = open(url).read
      @links = Set.new
      uri=URI(url)
      @base_path=""
      @base_path=(uri.scheme+"://"+uri.host+((uri.port==80 && "") || ":"+uri.port.to_s)) unless uri.host.nil?
      parse(content)
      download_to += File::SEPARATOR unless download_to.end_with?(File::SEPARATOR)
      mkdir(download_to)
      @links.each do |link|
        file=download_to + link.split("/")[-1]
        dump_to_file(file, open(link).read)
        files << file
      end unless uri.host.nil?
      files
    end

    # Callback method for notifying start of xml elements by REXML stream parser. 
    def tag_start(name, attrs) # :nodoc:
      if "a"==name
        href=attrs["href"]
        @links << @base_path + href if href.end_with?("xml") || href.end_with?("xsd")
      end
    end

    private
    def parse(text)
      REXML::Document.parse_stream(text, self)
    end

  end

end
