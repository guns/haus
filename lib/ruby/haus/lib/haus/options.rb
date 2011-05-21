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
    end

    def tap
      yield self
      self
    end

    def method_missing method, *args
      @ostruct.send method, *args
    end

    # Provides default value for HAUS_PATH
    def path
      @ostruct.path || File.expand_path('../../../..', __FILE__)
    end
  end
end
