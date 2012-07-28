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
    def initialize arg = nil, width = 32, indent = ' ' * 4
      # Send first arg to @ostruct or self
      if arg.is_a? Hash
        opts = arg
      else
        banner = arg
      end

      @ostruct        = OpenStruct.new opts
      @ostruct.path   = File.expand_path '../../..', __FILE__
      @ostruct.debug  = !!ENV['DEBUG']
      @ostruct.logger = Haus::Logger.new

      super banner, width, indent
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
