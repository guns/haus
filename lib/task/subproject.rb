# -*- encoding: utf-8 -*-

require 'haus/queue'
require 'haus/options'
require 'haus/logger'

class Task
  class Subproject
    include Haus::Loggable

    attr_accessor :base, :files, :fetch, :haus, :remote, :branch, :callback, :queue

    def initialize opts = {}
      @base     = opts[:base  ]
      @files    = opts[:files ]
      @fetch    = opts[:fetch ]
      @haus     = opts[:haus  ] || Haus::Options.new.path
      @remote   = opts[:remote] || 'origin'
      @branch   = OpenStruct.new Hash[[:upstream, :local].zip [opts[:branch]].flatten]
      @callback = OpenStruct.new :before => opts[:before], :after => opts[:after]
      @queue    = Haus::Queue.new :quiet => true
    end

    # Lazy require
    def git
      @git ||= (require 'git'; Git.open base)
    end

    def git_update
      stat = File.stat base

      git.checkout branch.upstream
      if fetch
        git.fetch remote
        git.merge [remote, branch.upstream].join('/')
      end

      if branch.local
        git.checkout branch.local
        if fetch
          git.merge branch.upstream, 'Merge branch %s into %s' % [branch.upstream, branch.local]
        end
      end
    ensure
      # We are likely running this as root, so restore original permissions
      FileUtils.chown_R stat.uid, stat.gid, base
    end

    def update_files
      case files
      # Map of (relative src) => (relative dst)
      when Hash
        files.each { |s, d| queue.add_copy File.join(base, s), File.join(haus, d) }
        queue.execute!
      # Relative rsync target directory
      when String
        dst = File.join haus, @files
        FileUtils.mkdir_p dst
        system *%W[rsync -a --delete --no-owner --exclude=.git --exclude=.bundle #{base}/ #{dst}/]
      # A function that returns a new value for @files
      when Proc
        @files = @files.call(self) and update_files # Recurse!
      # This is a pathogen bundle
      when :pathogen
        @files = File.join 'etc/vim/bundle', File.basename(base)
        update_files # Recurse!
      else
        raise 'No handler for :files as %s' % @files.class
      end
    end

    def update
      raise "#{base} does not exist" unless Dir.exists? base
      raise "No privileges to write #{haus}" unless File.writable? haus

      log "Updating subproject #{base}"

      git_update if branch.upstream
      callback.before.call self if callback.before
      update_files
      callback.after.call self if callback.after
    end
  end
end
