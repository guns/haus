# -*- encoding: utf-8 -*-

require 'haus/options'
require 'haus/queue'

class Haus
  #
  # Superclass for all Haus commands.
  #
  # Subclasses must define Task#call and should call Task::desc and
  # Task::banner in the class definition.
  #
  # The Options class can be extended via Options#tap
  #
  # Commands can also be invoked directly:
  #
  #   require 'haus/link'
  #   Haus::Link.new(%w[--noop]).run
  #
  # OR
  #
  #   require 'haus/link'
  #   h = Haus::Link.new
  #   h.options.noop = true
  #   h.call
  #
  # NOTE: Task#call does not parse arguments passed to Task#initialize
  #
  class Task
    class << self
      attr_accessor :command

      def list
        @@list ||= {}
      end

      def inherited base
        base.command = base.to_s.downcase.split('::').last
        list[base.command] = { :class => base, :desc => '', :banner => '' }
      end

      def desc msg
        list[command][:desc] = msg
      end

      def banner msg
        list[command][:banner] = msg
      end

      def summary
        list.map { |k,v| ' '*4 + '%-10s%s' % [k, v[:desc]] }.join "\n"
      end
    end

    def initialize args = []
      @args = args
    end

    # Accesses Task::list entry for the current subclass
    def meta
      self.class.list[self.class.command]
    end

    def queue
      @queue ||= Queue.new
    end

    # Common options for all tasks
    def options
      @options ||= Options.new do |opt|
        opt.summary_width = 20

        opt.banner = %Q{\
          #{meta[:banner] + "\n\n" unless meta.nil? or meta[:banner].empty?}\
          Usage: haus [--path PATH] #{self.class.command} [options]

          Options:
        }.gsub /^ +/, ''

        opt.on_tail '-f', '--force' do
          opt.force = true
        end

        opt.on_tail '-n', '--noop' do
          opt.noop  = true
          opt.force = true
        end

        opt.on_tail '-q', '--quiet' do
          opt.quiet = true
        end

        opt.on_tail '-h', '--help' do
          puts opt; exit
        end
      end
    end

    # Empty method for completeness
    def call args = []
    end

    # Command line interface; ruby libraries should directly call Task#call
    def run
      options.cli = true
      call options.parse(@args)
    end
  end
end
