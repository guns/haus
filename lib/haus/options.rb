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
    def initialize arg = nil, width = nil, indent = nil
      # Send first arg to @ostruct or self
      hash   = arg if arg.is_a? Hash
      banner = arg unless arg.is_a? Hash

      @ostruct        = OpenStruct.new hash
      @ostruct.path   = File.expand_path '../../..', __FILE__
      @ostruct.debug  = !!ENV['DEBUG']
      @ostruct.logger = Haus::Logger.new

      params = []
      params.push banner if banner
      params.push width  if width
      params.push indent if indent
      super *params
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
