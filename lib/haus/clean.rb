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
      users.each do |user|
        etcs  = etcfiles.map { |f| [f, user.dot(f)] }
        hiers = hierfiles.map { |f| [f, user.hier(f, etc)] }

        (etcs + hiers).each do |src, dst|
          begin
            if options.all
              queue.add_deletion dst
            elsif File.lstat(dst).ftype == 'link'
              queue.add_deletion dst if File.expand_path(File.readlink dst) == src
            end
          rescue Errno::ENOENT
            # We're not filtering non-extant files, so do nothing here
          rescue Errno::EACCES, Errno::ENOTDIR => e
            log ['!! ', :red, :bold], e.to_s
          end
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
