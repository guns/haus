# -*- encoding: utf-8 -*-

require 'haus/task'

class Haus
  class Link < Task
    desc 'Create dotfile symlinks'
    help "Create dotfile symlinks from #{Options.new.path}/etc/*"
    usage_tail '[pattern]'

    def initialize *args
      super
      options.relative = true
    end

    def options
      super.tap do |opt|
        opt.on '-a', '--absolute', 'Create absolute links instead of relative links' do
          opt.relative = false
        end
      end
    end

    def enqueue pattern = nil
      users.each do |user|
        hausfiles user do |src, dst|
          next if pattern and src !~ pattern
          if reason = user.distrusts(src)
            queue.annotate dst, ["WARNING: Source #{reason}", :red]
          end
          queue.add_link src, dst
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
