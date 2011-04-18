# -*- encoding: utf-8 -*-

require 'optparse'

module Haus
  class Command
    attr_accessor :opts

    def initialize args = []
      @args = args
    end

    # top level command has few options
    def options
      OptionParser.new do |opt|
        opt.banner = %Q{\
          Usage: haus [options] <COMMAND> [options]

          Options:
        }.gsub /^ +/, ''

        opt.on '-h', '--help' do
          puts opt; exit
        end

        opt.on '-v', '--version' do
          require 'haus/version'
          puts VERSION; exit
        end
      end
    end

    def run
      args = options.parse @args
      abort options.to_s if args.empty?
    end
  end
end
