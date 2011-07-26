# -*- encoding: utf-8 -*-

require 'haus/link'

class Haus
  class Copy < Link
    desc 'Copy dotfiles'
    help "#{Options.new.path}/etc/*"

    def enqueue
      users.each do |user|
        etcfiles.each do |src|
          queue.add_copy src, user.dotfile(src)
        end
      end
    end
  end
end
