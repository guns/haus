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
      @ostruct.path = File.expand_path '../../../..', __FILE__ # HAUS_PATH
    end

    def tap
      yield self
      self
    end

    def method_missing method, *args
      @ostruct.send method, *args
    end
  end
end
