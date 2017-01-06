# -*- encoding: utf-8 -*-

require 'find'
require 'haus/options'
require 'haus/user'
require 'haus/queue'

class Haus
  #
  # Superclass for all Haus commands.
  #
  # Subclasses must define Task#run and should call Task::desc and Task::help in
  # the class definition.
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
  #   h.run
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
        list[base.command] = { :class => base, :desc => '', :help => '' }
      end

      def desc msg
        list[command][:desc] = msg
      end

      def help msg
        list[command][:help] = msg
      end

      def usage_tail msg
        list[command][:usage_tail] = msg
      end

      def summary
        list.map { |k,v| '    %-8s%s' % [k, v[:desc]] }.join "\n"
      end
    end

    attr_reader :queue

    def initialize args = []
      @args  = args
      @queue = Queue.new :umask => 0077
    end

    # Accesses Task::list entry for the current subclass
    def meta
      self.class.list[self.class.command]
    end

    # List of Haus::User targets; shortcut to Task#options.users
    def users
      options.users
    end

    # Shortcut to logger method
    def log *args
      options.logger.log *args unless options.quiet
    end

    # HAUS_PATH/etc
    def etc
      File.join options.path, 'etc'
    end

    # Iterate over both dotfiles and hierfiles in HAUS_PATH/etc and the
    # corresponding user's home directory targets.
    #
    # Returns the table of sources and destinations.
    def hausfiles user
      # Ensure the passed object does what we need
      u = (user.respond_to? :dot and user.respond_to? :hier) ? user : Haus::User.new(user)

      # Construct, iterate, and return the file table
      table = dotfiles.map { |f| [f, u.dot(f)] } + hierfiles.map { |f| [f, u.hier(f, etc)] }
      table.each { |src, dst| yield src, dst } if block_given?
      table
    end

    # Returns non-hierdir files in HAUS_PATH/etc/*
    def dotfiles
      Dir["#{etc}/*"].reject { |f| hierdir? f }.map { |f| File.expand_path f }
    end

    # Returns hierfiles (files and directories within directories that begin
    # with `_`) in HAUS_PATH/etc/*
    #
    # Only the nodes of the tree are returned.
    #
    # e.g.
    #
    #   FileUtils.touch %w[/opt/haus/etc/_config/foorc
    #                      /opt/haus/etc/_config/foo.d/myfoorc
    #                      /opt/haus/etc/_foo/_bar/baz.conf]
    #
    #   Haus::Task.new(%w[--path /opt/haus]).hierfiles
    #   => ["/opt/haus/etc/_config/foorc",
    #       "/opt/haus/etc/_config/foo.d",
    #       "/opt/haus/etc/_foo/_bar/baz.conf"]
    #
    def hierfiles
      paths = []

      Dir["#{etc}/*"].select { |f| hierdir? f }.each do |hier|
        Find.find hier do |f|
          # Move on if the file is itself a hier dir or a dotfile
          next if File.basename(f) =~ /\A(_|\.)/

          # This is a non-hier node
          paths.push f

          # Don't recurse into a non-hier dir
          Find.prune if File.directory? f
        end
      end

      paths
    end

    def hierdir? path
      !!(File.directory? path and File.basename(path)[0] == '_')
    end

    #
    # Provides common options for all tasks
    #
    def options
      @options ||= Options.new do |opt|
        opt.instance_eval do
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

        opt.users = [Process.euid] # Default value for users array
        opt.summary_width = 18

        opt.banner = <<-BANNER.gsub /^ +/, ''
          #{meta[:help] + "\n\n" unless meta.nil? or meta[:help].empty?}\
          Usage: haus #{self.class.command} [options] #{meta[:usage_tail]}

          Options:
        BANNER

        opt.on '-p', '--path PATH', "Override the location of HAUS_PATH. Currently: #{opt.path}" do |arg|
          opt.path = arg
        end

        opt.on '-u', '--users a,b,c', Array, 'Usernames or UIDs; current user by default' do |arg|
          # Cast before sending
          opt.users = arg.map { |a| a =~ /\A\d+\z/ ? a.to_i : a.to_s }
        end

        opt.on_tail '-f', '--force', 'Act without confirmation' do
          opt.force = true
        end

        opt.on_tail '-n', '--noop', 'Do not make any changes, but show what would happen' do
          opt.noop = true
        end

        opt.on_tail '-q', '--quiet', 'Produce no output; confirmation prompts fail silently' do
          opt.quiet = true
        end
      end
    end

    # Subclasses should run super, which returns any non-option arguments
    def run
      options.parse @args
    end
  end
end
