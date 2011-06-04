# -*- encoding: utf-8 -*-

require 'haus/version'
require 'haus/options'
require 'haus/task'
require 'haus/link'

#
# CLI interface, intended to be run as Haus.new(ARGV).run
#
# Library interface is exposed through instances of Haus::Task subclasses
#
class Haus
  def initialize args = []
    @args = args
  end

  def help
    %Q{\
      Usage: haus [--path PATH] COMMAND [command-options]

      Options:
          -p, --path /path/to/your/haus
                    Override the location of HAUS_PATH, which is otherwise
                    determined through the location of this script.
                    Default: #{options.path}

      Commands:
      #{Task.summary}

      See `haus COMMAND --help' for more information on each command\
    }.gsub /^ {6}/, ''
  end

  # Options for top level command
  def options
    @options ||= Options.new do |opt|
      opt.on '-p', '--path PATH' do |arg|
        opt.path = arg
      end

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
    t = task[:class].new args[1..-1]
    t.options.path = options.path if options.path
    t.run
  end
end
