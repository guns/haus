# -*- encoding: utf-8 -*-

require 'haus/task'

class Haus
  class Link < Task
    desc 'Create dotfile symlinks'
    help "Create dotfile symlinks from #{Options.new.path}/etc/*"

    def enqueue
      users.each do |user|
        etcfiles.each do |src|
          queue.add_link src, user.dotfile(src)
        end
      end
    end

    def call args = []
      enqueue
      queue.options = options
      queue.execute
    end
  end
end
