# -*- encoding: utf-8 -*-

require 'haus/task'

class Haus
  class Clean < Task
    desc 'Clean up dotfiles'
    help 'Clean up dotfiles'

    def options
      super.tap do |opt|
        opt.on '-a', '--all', 'Clean regular files and directories in addition to symlinks' do
          opt.all = true
        end
      end
    end

    def enqueue
      etcnames = etcfiles.map { |f| '.' + File.basename(f) } if options.all

      users.each do |user|
        user.dotfiles.each do |dot|

          begin
            if options.all
              queue.add_deletion dot if etcnames.include? File.basename(dot)
            elsif File.lstat(dot).ftype == 'link'
              queue.add_deletion dot if etcfiles.include? File.expand_path(File.readlink dot)
            end
          rescue Errno::EACCES, Errno::ENOENT => e # Catch syscall errors
            # FIXME: logger!
            warn e.to_s
          end

        end
      end
    end

    def run
      args = super
      abort options.to_s if args.size > 0
      queue.options = options
      enqueue
      queue.execute
    end
  end
end
