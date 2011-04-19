# -*- encoding: utf-8 -*-

require 'haus/version'
require 'haus/options'
require 'haus/link'

class Haus
  def initialize args = []
    @args = args
  end

  def help
    %Q{\
      Usage: haus [--help|--version] COMMAND [options]

      Commands:
      #{Task.summary}

      See `haus COMMAND --help' for more information on each command\
    }.gsub /^ {6}/, ''
  end

  # top level command has few options
  def options
    Options.new do |opt|
      opt.on '-h', '--help' do
        puts help; exit
      end

      opt.on '-v', '--version' do
        puts VERSION; exit
      end
    end
  end

  def run
    args = options.order @args
    task = Task.list[args.first]
    abort help if task.nil?

    # NOTE: Enumerable#drop introduced in 1.8.7
    task[:class].new.run args[1..-1]
  end
end
