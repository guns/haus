# -*- encoding: utf-8 -*-

require 'haus/task'

class Haus
  class Copy < Task
    desc 'Copy dotfiles'
    help "Copy dotfiles from #{Options.new.path}/etc/*"

    def enqueue
      users.each do |user|
        etcfiles.each do |src|
          queue.add_copy src, user.dotfile(src)
        end
      end
    end

    def call args = []
      queue.options = options
      enqueue
      queue.execute
    end
  end
end
