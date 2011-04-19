# -*- encoding: utf-8 -*-

require 'haus/options'

class Haus
  #
  # Superclass for all Haus commands.
  #
  # Subclasses must define Task#execute and should call Task::desc and
  # Task::banner in the class definition.
  #
  # The Options class can be extended via Options#tap
  #
  # Commands can also be invoked directly:
  #
  #   require 'haus/link'
  #   Haus::Link.new.call %w[--force]
  #
  class Task
    class << self
      def list
        @@list ||= {}
      end

      attr_accessor :command

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
        list.map { |k,v| '    %-10s%s' % [k, v[:desc]] }.join "\n"
      end

      def haus_root
        @haus_root ||= File.expand_path '../../..', '__FILE__'
      end
    end

    # Accesses Task::List entry for the current subclass
    def meta
      self.class.list[self.class.command]
    end

    def haus_root
      self.class.haus_root
    end

    # all user dotfiles in etc/, except for the ssh directory
    def dotfiles
      @dotfiles ||= Dir[haus_root + '/etc/*'].reject { |f| f =~ %r{/ssh\z} }
    end

    # Common options for all tasks
    def options
      @options ||= Options.new do |opt|
        opt.summary_width = 20

        opt.banner = %Q{\
          #{meta[:banner] + "\n\n" unless meta[:banner].empty?}\
          Usage: haus [--help|--version] #{self.class.command} [options]

          Options:
        }.gsub /^ +/, ''

        opt.on_tail '-f', '--force', 'Suppress all prompts and answer affirmatively' do
          opt.force = true
        end

        opt.on_tail '-n', '--dry-run', "Don't make any changes, but report on what would have been done" do
          opt.dry_run = true
          opt.force   = true
        end

        opt.on_tail '-q', '--quiet' do
          opt.quiet = true
        end

        opt.on_tail '-h', '--help' do
          puts opt; exit
        end
      end
    end

    def execute args = []
    end

    # command line interface; ruby libraries should directly call Task#execute
    def run args = []
      options.cli = true
      execute options.parse(args)
    end
  end
end
