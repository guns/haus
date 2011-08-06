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
# Haus::Task subclasses never call Kernel#exit or Kernel#abort, and always log
# to the specified logger, so Ruby libraries should invoke those instead.
#
class Haus
  def initialize args = []
    @args = args
  end

  def help
    %Q{\
      Usage: haus COMMAND [options]

      Commands:
      #{Task.summary}

      See `haus COMMAND --help` for more information on each command\
    }.gsub /^ {6}/, ''
  end

  # Options for top level command
  def options
    @options ||= Options.new do |opt|
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
    task[:class].new(args[1..-1]).run
  rescue StandardError => e
    abort e.to_s
  end
end
