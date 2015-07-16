# -*- encoding: utf-8 -*-

require 'find'
require 'shellwords'
require 'haus/task'
require 'haus/utils'

class Haus
  class Unlink < Task
    desc 'Remove dotfile symlinks'
    help 'Remove dotfile symlinks'

    def options
      super.tap do |opt|
        opt.on '-a', '--all', 'Search all dotfiles for broken symlinks (slow)' do
          opt.all = true
        end

        opt.on '-b', '--broken', 'Remove broken symlinks (slow)' do |arg|
          opt.broken = true
        end
      end
    end

    def all_dotfiles dir
      Dir['%s/.*' % dir.shellescape].each do |f|
        b = File.basename f
        next if b == '.' or b == '..'

        # Find#find runs File.exist? on its arguments thereby raising on
        # broken symlinks, which is exactly what we're looking for! We'll have
        # to pass known extant directories instead.
        if File.directory? f
          Find.find(f) { |p| yield p }
        else
          yield f
        end
      end
    end

    def enqueue
      users.each do |user|
        if options.all or options.broken
          haus = Regexp.compile '\A%s/' % options.path
          all_dotfiles user.dir do |dst|
            if File.symlink? dst
              src = Haus::Utils.readlink dst
              if src =~ haus
                if options.all or (options.broken and not queue.extant? src)
                  queue.add_deletion dst
                end
              end
            end
          end
        else
          hausfiles user do |src, dst|
            begin
              if File.symlink? dst and Haus::Utils.readlink(dst) == src
                queue.add_deletion dst
              end
            rescue Errno::ENOENT
              # We're not filtering non-extant files, so do nothing here
            rescue Errno::EACCES, Errno::ENOTDIR => e
              log ['!! ', :red, :bold], e.to_s
            end
          end
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
