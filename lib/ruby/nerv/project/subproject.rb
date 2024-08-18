# -*- encoding: utf-8 -*-

require 'git'
require 'haus/queue'
require 'haus/options'
require 'haus/logger'

module NERV; end
module NERV::Project; end

class NERV::Project::Subproject
  include Haus::Loggable

  attr_accessor :base, :push, :haus, :pull, :branch, :callback

  def initialize opts = {}
    @base     = opts[:base ]
    @files    = opts[:files]
    @push     = opts[:push ]
    @pull     = opts[:pull ] || 'origin'
    @haus     = opts[:haus ] || Haus::Options.new.path
    @branch   = OpenStruct.new Hash[[:upstream, :local].zip [opts[:branch]].flatten]
    @callback = OpenStruct.new :before => opts[:before], :after => opts[:after]
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
      home = ENV['HOME']
      ENV['HOME'] = user.dir
      yield
    else
      yield
    end
  ensure
    Process.gid = gid if gid
    Process.uid = uid if uid
    Process.euid = euid if euid
    ENV['HOME'] = home if home
  end

  def git
    @git ||= Git.open base
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

  def update_files files
    case files
    # Recursively contains any of the below
    when Array
      files.each { |fs| update_files fs }
    # Map of (relative src) => (relative dst)
    when Hash
      q = Haus::Queue.new :quiet => true
      files.each { |s, d| q.add_copy File.join(base, s), File.join(haus, d) }
      q.execute!
    # Relative rsync target directory
    when String
      dst = File.join haus, files
      FileUtils.rm_f dst if File.symlink? dst
      FileUtils.mkdir_p dst
      system *%W[rsync -a --delete --no-owner --exclude=.git --exclude=.bundle #{base}/ #{dst}/]
    # A function that returns a new value for files
    when Proc
      fs = files.call(self) and update_files fs
    # This is a pathogen bundle
    when :pathogen
      update_files File.join('etc/vim/bundle', File.basename(base))
    else
      raise 'No handler for :files as %s' % files.class
    end
  end

  def update
    raise "#{base} does not exist" unless Dir.exist? base
    raise "No privileges to write #{haus}" unless File.writable? haus

    log "Updating subproject #{base}"

    uid = File.stat(base).uid

    Dir.chdir(base) { as_uid(uid) { callback.before.call self } } if callback.before
    as_uid(uid) { git_update } if branch.upstream
    update_files @files
    as_uid(uid) { git_push } if push and fetch
    Dir.chdir(base) { as_uid(uid) { callback.after.call self } } if callback.after
  end
end
