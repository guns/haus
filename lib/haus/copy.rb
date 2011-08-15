# -*- encoding: utf-8 -*-

require 'haus/task'

class Haus
  class Copy < Task
    desc 'Copy dotfiles'
    help "Copy dotfiles from #{Options.new.path}/etc/*"

    def enqueue
      users.each do |user|
        etcfiles.each do |src|
          queue.add_copy src, user.dot(src)
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
