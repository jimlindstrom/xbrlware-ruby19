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

  # Method to grep xbrl file names from given dir
  # File names of xbrl documents has to be in the following convention to use this method,
  #    calculation linkbase document must end with _cal.xml
  #    definition linkbase document must end with _def.xml
  #    presentation linkbase document must end with _pre.xml
  #    label linkbase document must end with _lab.xml
  #    taxonomy file muse end with .xsd
  def self.file_grep (dir_path=".")

    taxonomy_file=nil
    instance_file=nil

    pre_file=nil
    cal_file=nil
    lab_file=nil
    def_file=nil
    ref_file=nil

    files=Dir[dir_path+File::SEPARATOR+"*"]

    files.each do |file|
      case
        when file.end_with?(".xsd")
          taxonomy_file = file
        when file.end_with?("pre.xml")
          pre_file = file
        when file.end_with?("cal.xml")
          cal_file = file
        when file.end_with?("def.xml")
          def_file = file
        when file.end_with?("lab.xml")
          lab_file = file
        when file.end_with?("ref.xml")
          ref_file = file
        when file.end_with?(".xml")
          instance_file = file
      end
    end

    {"ins" => instance_file, "tax" => taxonomy_file, "pre" => pre_file, "cal" => cal_file, "lab" => lab_file, "def" => def_file, "ref" => ref_file}
  end

  # Initializes and returns an Instance.
  #
  # instance_string::
  #   XBRL Instance source. Could be one of the following:
  #
  #   - nil: Tries to load and parse '<scriptname>.xml'.
  #   - filename: Tries to load and parse filename.
  #   - IO object: Reads from object until EOF is detected and parses result.
  #   - XML string: Parses string.
  #
  # taxonomy_string::
  #   optional parameter, XBRL Taxonomy source. Could be one of the following:
  #
  #   - nil: taxonomy file specified in the instance file would be used if present.
  #   - filename: Tries to load and parse filename., taxonomy file specified in the instance document will be ignored
  #   - IO object: Reads from object until EOF is detected and parses result, taxonomy file specified in the instance document will be ignored
  #   - XML string: Parses string, taxonomy file specified in the instance document will be ignored
  #
  def self.ins(instance_string, taxonomy_string=nil)
    Instance.new(instance_string, taxonomy_string=nil)
  end

end
