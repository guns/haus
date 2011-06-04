# -*- encoding: utf-8 -*-

require 'haus/options'
require 'haus/queue'
require 'haus/user'

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

      @@list = {}
      def list
        @@list
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

    class TaskOptions < Options
      def users= ary
        users = ary.map { |a| User.new a }
        users.each do |u|
          if not File.directory? u.dir
            raise "#{u.name}'s home directory, #{u.dir.inspect}, does not exist"
          end
        end
        super users
      end
    end

    attr_reader :queue

    def initialize args = []
      @args  = args
      @queue = Queue.new
    end

    # Accesses Task::list entry for the current subclass
    def meta
      self.class.list[self.class.command]
    end

    # List of Haus::User targets; shortcut to Task#options.users
    def users
      options.users
    end

    # HAUS_PATH/etc
    def etc
      File.join options.path, 'etc'
    end

    # HAUS_PATH/etc/*
    def etcfiles
      Dir["#{etc}/*"].map { |f| File.expand_path f }
    end

    # Common options for all tasks
    def options
      @options ||= TaskOptions.new do |opt|
        opt.users = [Process.euid] # Default value for users array
        opt.summary_width = 20     # Lines up with Haus#help

        opt.banner = %Q{\
          #{meta[:banner] + "\n\n" unless meta.nil? or meta[:banner].empty?}\
          Usage: haus [--path PATH] #{self.class.command} [options]

          Options:
        }.gsub /^ +/, ''

        opt.on '-u', '--users a,b,c', Array,
               'Apply changes to given users instead of the current user;',
               'users can be specified as usernames or UIDs' do |arg|
          # Cast before sending
          opt.users = arg.map { |a| a =~ /\A\d+\z/ ? a.to_i : a.to_s }
        end

        opt.on_tail '-f', '--force' do
          opt.force = true
        end

        opt.on_tail '-n', '--noop' do
          opt.noop = true
        end

        opt.on_tail '-v', '--verbose' do
          opt.verbose = true
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
      call options.parse(@args)
    end
  end
end
