# -*- encoding: utf-8 -*-

require 'haus/options'

class Haus
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

      # One line description
      def desc msg = ''
        list[command][:desc] = msg
      end

      def banner msg = ''
        list[command][:banner] = msg
      end

      def summary
        list.map { |k,v| '    %-10s%s' % [k, v[:desc]] }.join "\n"
      end
    end

    def meta
      self.class.list[self.class.command]
    end

    # default options for all tasks; subclasses should call super.tap
    def options
      @options ||= Options.new do |opt|
        opt.summary_width = 20

        opt.banner = %Q{\
          #{meta[:banner] + "\n\n" unless meta[:banner].empty?}\
          Usage: haus [--help|--version] #{self.class.command} [options]

          Options:
        }.gsub /^ +/, ''

        opt.on_tail '-n', '--dry-run', "Don't make any changes, but report on what would have been done" do
          opt.dry_run = true
          opt.force   = true
        end

        opt.on_tail '-f', '--force', 'Suppress all prompts and answer affirmatively' do
          opt.force = true
        end

        opt.on_tail '-h', '--help' do
          puts opt; exit
        end
      end
    end

    # Subclasses must define #options and #execute
    def call args = []
      execute options.parse(args)
    end
  end
end
