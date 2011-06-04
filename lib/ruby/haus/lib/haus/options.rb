# -*- encoding: utf-8 -*-

require 'optparse'
require 'ostruct'

class Haus
  #
  # A hybrid OptionParser / OpenStruct class.
  #
  # Options#path provides default value of HAUS_PATH
  #
  class Options < OptionParser
    def initialize
      @ostruct = OpenStruct.new
      @ostruct.path = File.expand_path '../../../../../..', __FILE__ # HAUS_PATH
      super
    end

    # HAUS_PATH/etc
    def etc
      File.join path, 'etc'
    end

    # HAUS_PATH/etc/*
    def etcfiles
      Dir["#{etc}/*"].map { |f| File.expand_path f }
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
