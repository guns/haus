# -*- encoding: utf-8 -*-

require 'optparse'
require 'ostruct'

class Haus
  #
  # A hybrid OptionParser / OpenStruct class.
  #
  class Options < OptionParser
    def initialize
      super
      @ostruct = OpenStruct.new
      @ostruct.path = File.expand_path '../../../../../..', __FILE__ # HAUS_PATH
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
