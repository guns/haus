# -*- encoding: utf-8 -*-

require 'haus/task'

class Haus
  class Link < Task
    desc 'Create dotfile symlinks'
    help "Create dotfile symlinks from #{Options.new.path}/etc/*"

    def options
      super.tap do |opt|
        opt.on '-r', '--relative', 'Create relative links instead of absolute links' do
          opt.relative = true
        end
      end
    end

    def enqueue
      users.each do |user|
        etcfiles.each do |src|
          queue.add_link src, user.dot(src)
        end

        hierfiles.each do |src|
          queue.add_link src, user.hier(src, etc)
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
