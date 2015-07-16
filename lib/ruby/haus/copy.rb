# -*- encoding: utf-8 -*-

require 'haus/task'

class Haus
  class Copy < Task
    desc 'Copy dotfiles'
    help "Copy dotfiles from #{Options.new.path}/etc/*"

    def enqueue
      users.each do |user|
        hausfiles user do |src, dst|
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
      raise options.to_s if args.size > 0
      queue.options = options
      enqueue
      queue.execute
    end
  end
end
