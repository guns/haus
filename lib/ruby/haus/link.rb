# -*- encoding: utf-8 -*-

require 'haus/task'

class Haus
  class Link < Task
    desc 'Create dotfile symlinks'
    help "Create dotfile symlinks from #{Options.new.path}/etc/*"

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

    def enqueue
      users.each do |user|
        hausfiles user do |src, dst|
          if reason = user.distrusts(src)
            queue.annotate dst, ["WARNING: Source #{reason}", :red]
          end
          queue.add_link src, dst
        end
      end
    end

    def run
      args = super
      raise options.to_s if args.size > 0
      queue.options = options
      enqueue
      queue.execute
    end
  end
end
