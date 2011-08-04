# -*- encoding: utf-8 -*-

require 'haus/version'
require 'haus/options'
require 'haus/task'
require 'haus/link'
require 'haus/copy'
require 'haus/clean'

#
# Command line interface, intended to be run as Haus.new(ARGV).run
#
class Haus
  def initialize args = []
    @args = args
  end

  def help
    %Q{\
      Usage: haus [--path PATH] COMMAND [command-options]

      Options:
          -p, --path #{options.path}
                  Override the location of HAUS_PATH, which is otherwise
                  determined through the location of this script.

      Commands:
      #{Task.summary}

      See `haus COMMAND --help` for more information on each command\
    }.gsub /^ {6}/, ''
  end

  # Options for top level command
  def options
    @options ||= Options.new do |opt|
      opt.on '-p', '--path PATH' do |arg|
        opt.path = arg
      end

      # Suppress regular OptionParser help output
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

    # Enumerable#drop introduced in 1.8.7
    t = task[:class].new args[1..-1]
    t.options.path = options.path
    t.run
  end
end
