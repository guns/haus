# -*- encoding: utf-8 -*-

require 'optparse'
require 'haus/version'
require 'haus/link'

class Haus
  def initialize args = []
    @args = args
  end

  def help
    %Q{\
      Usage: haus [--help|--version] COMMAND [options]

      Commands:
      #{Task.list.map { |k,v| '    %-12s%s' % [k, v[:desc]] }}

      See `haus COMMAND --help' for more information on each command\
    }.gsub /^ {6}/, ''
  end

  # top level command has few options
  def options
    OptionParser.new do |opt|
      opt.on '-h', '--help' do
        puts opt; exit
      end

      opt.on '-v', '--version' do
        puts VERSION; exit
      end
    end
  end

  def run
    args = options.order @args
    abort help if args.empty?
  end
end
