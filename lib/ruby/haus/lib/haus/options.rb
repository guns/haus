# -*- encoding: utf-8 -*-

require 'optparse'
require 'ostruct'
require 'haus/user'

class Haus
  #
  # A hybrid OptionParser / OpenStruct class.
  #
  class Options < OptionParser
    def initialize
      super
      @ostruct = OpenStruct.new
      @ostruct.path = File.expand_path '../../../../../..', __FILE__ # HAUS_PATH
      @ostruct.users = [User.new]
    end

    def users= ary
      @ostruct.users = ary.map do |a|
        u = User.new a
        if not File.directory? u.dir
          raise "#{u.name}'s home directory, #{u.dir.inspect}, does not exist"
        end
        u
      end
    end

    def method_missing *args
      @ostruct.send *args
    end

    # Ruby 1.9 has Object#tap
    def tap
      yield self
      self
    end unless respond_to? :tap
  end
end
