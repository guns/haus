# -*- encoding: utf-8 -*-

require 'haus/version'
require 'haus/options'
require 'haus/logger'
require 'haus/task'
require 'haus/link'
require 'haus/copy'
require 'haus/unlink'

#
# Command line interface, intended to be run as Haus.new(ARGV).run
#
# Haus::Task subclasses never call Kernel#exit and always log to the specified
# logger, so Ruby libraries should invoke those instead.
#
class Haus
  include Loggable

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
        log help; exit
      end

      opt.on '-v', '--version' do
        log VERSION; exit
      end
    end
  end

  def run
    args = options.order @args
    task = Task.list[args.first]

    if task.nil?
      log help
      exit 1
    end

    # Enumerable#drop unavailable in 1.8.6
    task[:class].new(args[1..-1]).run or exit 1
  rescue StandardError => e
    log ["[#{e.class}] ", :red, :bold], e.to_s
    log e.backtrace.join "\n"
    exit 1
  end
end
