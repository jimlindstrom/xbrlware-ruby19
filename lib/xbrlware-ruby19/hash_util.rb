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
  module HashUtil # :nodoc:
    def self.to_obj(hash)
      o = Object.new()
      hash.each do |k, v|
        v=self.to_obj(v) if v.is_a?(Hash)
        MetaUtil::introduce_instance_var(o, k, v)
      end
      return o
    end

    # In Ruby 1.9, the Hash is ordered by default.
    if RUBY_VERSION >= '1.9'
      OHash = ::Hash
    else
      class OHash < Hash #:nodoc:
        def initialize(*args, &block)
          super
          @keys = []
        end

        def self.[](*args)
          ordered_hash = new

          if (args.length == 1 && args.first.is_a?(Array))
            args.first.each do |key_value_pair|
              next unless (key_value_pair.is_a?(Array))
              ordered_hash[key_value_pair[0]] = key_value_pair[1]
            end

            return ordered_hash
          end

          unless (args.size % 2 == 0)
            raise ArgumentError.new("odd number of arguments for Hash")
          end

          args.each_with_index do |val, ind|
            next if (ind % 2 != 0)
            ordered_hash[val] = args[ind + 1]
          end

          ordered_hash
        end

        def initialize_copy(other)
          super
          # make a deep copy of keys
          @keys = other.keys
        end

        def []=(key, value)
          @keys << key if !has_key?(key)
          super
        end

        def keys
          @keys.dup
        end

        def values
          @keys.collect { |key| self[key] }
        end

        def delete(key)
          if has_key? key
            index = @keys.index(key)
            @keys.delete_at index
          end
          super
        end

        def delete_if
          super
          sync_keys!
          self
        end

        def reject!
          super
          sync_keys!
          self
        end

        def reject(&block)
          dup.reject!(&block)
        end

        def to_hash
          self
        end

        def to_a
          @keys.map { |key| [ key, self[key] ] }
        end

        def each_key
          @keys.each { |key| yield key }
        end

        def each_value
          @keys.each { |key| yield self[key]}
        end

        def each
          @keys.each {|key| yield [key, self[key]]}
        end

        alias_method :each_pair, :each

        def clear
          super
          @keys.clear
          self
        end

        def shift
          k = @keys.first
          v = delete(k)
          [k, v]
        end

        def merge!(other_hash)
          other_hash.each {|k, v| self[k] = v }
          self
        end

        def merge(other_hash)
          dup.merge!(other_hash)
        end

        # replace with keys from other Hash. The other Hash could be ordered or not ordered.
        def replace(other)
          super
          @keys = other.keys
          self
        end

        def inspect
          "#<OHash #{super}>"
        end

        # XmlSimple's export to xml from Hash depends on instance_of?(Hash)
        def instance_of?(clazz)
          self.is_a?(clazz)
        end

        private

        def sync_keys!
          @keys.delete_if {|k| !has_key?(k)}
        end
      end
    end
  end
end