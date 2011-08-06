# -*- encoding: utf-8 -*-

require 'optparse'
require 'ostruct'
require 'haus/logger'

class Haus
  #
  # A hybrid OptionParser / OpenStruct class.
  #
  # Options#path provides default value of HAUS_PATH
  # Options#logger provides default logger
  #
  class Options < OptionParser
    def initialize
      @ostruct = OpenStruct.new
      @ostruct.path = File.expand_path '../../..', __FILE__ # HAUS_PATH
      @ostruct.logger = Haus::Logger.new
      super
    end

    def path= arg
      @ostruct.path = File.expand_path arg
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
