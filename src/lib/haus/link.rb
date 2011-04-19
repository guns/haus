# -*- encoding: utf-8 -*-

require 'haus/task'

class Haus
  class Link < Task
    desc 'Symlink user dotfiles'
    banner %Q{Create home dotfile symlinks to #{haus_root}/etc/*}

    def options
      super.tap do |opt|
        opt.on '-u', '--users A,B,C', Array,
               "Install to specified users' home directories;",
               'only the root user may use this option' do |arg|
          opt.users = arg
        end
      end
    end

    def call args
      queue.tty_confirm?
    end
  end
end
