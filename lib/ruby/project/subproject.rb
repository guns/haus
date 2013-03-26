# -*- encoding: utf-8 -*-

require 'haus/queue'
require 'haus/options'
require 'haus/logger'

module Project
  class Subproject
    include Haus::Loggable

    attr_accessor :base, :files, :push, :haus, :pull, :branch, :callback, :queue

    def initialize opts = {}
      @base     = opts[:base ]
      @files    = opts[:files]
      @push     = opts[:push ]
      @pull     = opts[:pull ] || 'origin'
      @haus     = opts[:haus ] || Haus::Options.new.path
      @branch   = OpenStruct.new Hash[[:upstream, :local].zip [opts[:branch]].flatten]
      @callback = OpenStruct.new :before => opts[:before], :after => opts[:after]
      @queue    = Haus::Queue.new :quiet => true
      @fetch    = opts[:fetch]
    end

    def fetch
      @fetch == true
    end

    def fetch= value
      @fetch = value unless @fetch == :never
    end

    def as_uid uid
      if Process.euid.zero?
        user = Etc.getpwuid uid
        euid, uid, gid = Process.euid, Process.uid, Process.gid
        Process.gid = user.gid
        Process.uid = user.uid
        Process.euid = user.uid
        yield
      else
        yield
      end
    ensure
      Process.gid = gid if gid
      Process.uid = uid if uid
      Process.euid = euid if euid
    end

    # Lazy require
    def git
      @git ||= (require 'git'; Git.open base)
    end

    def git_update
      git.checkout branch.upstream
      if fetch
        git.fetch pull
        git.merge [pull, branch.upstream].join('/')
      end

      if branch.local
        git.checkout branch.local
        if fetch
          git.merge branch.upstream, 'Merge branch %s into %s' % [branch.upstream, branch.local]
        end
      end
    end

    def git_push
      git.push push, '--all'
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
        raise "#{dst} is a symbolic link" if File.symlink? dst
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

      uid = File.stat(base).uid

      Dir.chdir(base) { as_uid(uid) { callback.before.call self } } if callback.before
      as_uid(uid) { git_update } if branch.upstream
      update_files
      as_uid(uid) { git_push } if push and fetch
      Dir.chdir(base) { as_uid(uid) { callback.after.call self } } if callback.after
    end
  end
end
