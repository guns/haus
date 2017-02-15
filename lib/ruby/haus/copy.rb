# -*- encoding: utf-8 -*-

require 'haus/task'

class Haus
  class Copy < Task
    desc 'Copy dotfiles'
    help "Copy dotfiles from #{Options.new.path}/etc/*"
    usage_tail '[pattern]'

    def options
      super.tap do |opt|
        opt.on '-n', '--no-overwrite', 'Do not overwrite existing files' do
          opt.no_overwrite = true
        end
      end
    end

    def enqueue pattern = nil
      users.each do |user|
        hausfiles user do |src, dst|
          next if pattern and src !~ pattern
          next if options.no_overwrite and File.exists? dst
          if reason = user.distrusts(src)
            queue.annotate dst, ["WARNING: Source #{reason}", :red]
          end
          queue.add_copy src, dst
        end
      end
    end

    def run
      return nil if queue.executed?
      args = super
      raise options.to_s if args.size > 1
      queue.options = options
      enqueue args[0] ? Haus::Utils::regexp_parse(args[0]) : nil
      queue.execute
    end
  end
end
