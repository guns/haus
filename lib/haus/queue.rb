# -*- encoding: utf-8 -*-

require 'fileutils'
require 'ostruct'
require 'pathname'
require 'haus/logger'

class Haus
  #
  # Instead of executing filesystem calls immediately, Haus::Task instances
  # register jobs via Queue#add_*, which can then be executed after optional
  # user confirmation.
  #
  # For safety, the individual job queues are frozen; jobs can be removed from
  # the queue via Queue#remove. In addition, multiple jobs are not allowed to be
  # queued for a single destination.
  #
  # Before execution, any files that would be overwritten, modified, or removed
  # are saved to an archive. If an error is raised during execution, the archive
  # is extracted in an attempt to restore the previous state (however, no
  # attempt is made to remove any newly created files).
  #
  class Queue
    class MultipleJobError < RuntimeError; end

    attr_reader :options, :archive_path, :links, :copies, :modifications, :deletions

    def initialize opts = nil
      self.options = opts || OpenStruct.new
      options.logger ||= Haus::Logger.new

      @links, @copies, @modifications, @deletions = (1..4).map { [].freeze }

      # Array#shuffle and Enumerable#take introduced in 1.8.7
      time = Time.now.strftime '%Y-%m-%d'
      salt = ('a'..'z').sort_by { rand }[0..7].join
      @archive_path = "/tmp/haus-#{time}-#{salt}.tar.gz".freeze
    end

    # Parameter can be a Hash or an OpenStruct
    def options= opts
      @options = opts.is_a?(Hash) ? OpenStruct.new(opts) : opts.dup
    end

    # Add symlinking operation;
    # noop if source does not exist or destination already points to source
    def add_link source, destination
      src, dst = [source, destination].map { |f| File.expand_path f }

      raise MultipleJobError if targets.include? dst
      return nil unless File.exists? src
      return nil if File.symlink? dst and linked? src, dst

      @links = (links.dup << [src, dst]).freeze
    end

    # Add copy operation;
    # noop if source does not exist or source and destination are copies
    def add_copy source, destination
      src, dst = [source, destination].map { |f| File.expand_path f }

      raise MultipleJobError if targets.include? dst
      return nil unless File.exists? src
      return nil if File.exists? dst and duplicates? src, dst

      @copies = (copies.dup << [src, dst]).freeze
    end

    # Add deletion operation;
    # noop if destination does not exist
    def add_deletion destination
      dst = File.expand_path destination

      raise MultipleJobError if targets.include? dst
      return nil unless File.exists? dst

      @deletions = (deletions.dup << dst).freeze
    end

    # Add modification operation;
    # Parameter is the file to be modified, block is the actual operation, which
    # in turn takes the file to be modified as an argument.
    #
    #   q = Queue.new
    #   q.add_modification 'smilies.txt' do |path|
    #     File.open(path, 'a') { |f| f.puts ':)' }
    #   end
    #
    # Raises ArgumentError if passed path is a directory.
    #
    # NOTE: The passed file will be created/updated with FileUtils#touch before
    #       block is called
    #
    def add_modification destination, &block
      dst = File.expand_path destination

      raise MultipleJobError if targets.include? dst
      raise ArgumentError if File.directory? dst
      return nil if block.nil?

      @modifications = (modifications.dup << [block, dst]).freeze
    end

    # Return list of destinations that are queued to be visited
    def targets action = :all
      case action
      when :all       then (links + copies + modifications).map { |s,d| d } + deletions
      when :delete    then deletions
      # Links, copies, and modifications may create files
      when :create    then (targets - targets(:delete)).reject { |f| File.exists? f }
      # Modifications to files that already exist
      when :modify    then modifications.map { |s,d| d } - targets(:create)
      # Extant files that will be wholly replaced by links and copies
      when :overwrite then targets - targets(:create) - targets(:modify) - targets(:delete)
      # Extant targets that should be archived
      when :archive   then targets - targets(:create)
      else raise ArgumentError
      end
    end

    def hash
      (links + copies + modifications + deletions).hash
    end

    # Remove jobs by destination path; boolean return
    def remove destination
      h = hash

      dst            = File.expand_path destination
      @links         = links.dup.reject { |s,d| d == dst }.freeze
      @copies        = copies.dup.reject { |s,d| d == dst }.freeze
      @modifications = modifications.dup.reject { |s,d| d == dst }.freeze
      @deletions     = deletions.dup.reject { |d| d == dst }.freeze

      hash != h
    end

    # Execute jobs after user confirmation.
    def execute
      execute! if tty_confirm?
    end

    # Execute jobs immediately.
    #
    # Modifications are processed last.
    def execute!
      # Guard against multiple executions
      return nil if executed?
      @executed = true

      begin
        did_archive = archive unless options.noop
        old_umask = File.umask 0077

        # Rollback on signals
        %w[INT TERM QUIT].each do |sig|
          trap(sig) { raise "Caught signal SIG#{sig}" }
        end

        fopts = { :noop => options.noop }

        deletions.each do |dst|
          log [':: ', :green, :bold], ['DELETING ', :italic], dst
          FileUtils.rm_rf dst, fopts.merge(:secure => true)
        end

        links.each do |src, dst|
          srcpath = options.relative ? relpath(src, dst) : src

          log [':: ', :green, :bold], ['LINKING ', :italic], [srcpath, dst].join(' → ') # NOTE: utf8 char
          FileUtils.rm_rf dst, fopts.merge(:secure => true)
          FileUtils.mkdir_p File.dirname(dst), fopts

          FileUtils.ln_s srcpath, dst, fopts
        end

        copies.each do |src, dst|
          log [':: ', :green, :bold], ['COPYING ', :italic], [src, dst].join(' → ') # NOTE: utf8 char
          FileUtils.rm_rf dst, fopts.merge(:secure => true)
          FileUtils.mkdir_p File.dirname(dst), fopts
          FileUtils.cp_r src, dst, fopts.merge(:dereference_root => false) # Copy symlinks as is
        end

        modifications.each do |prc, dst|
          log [':: ', :green, :bold], ['MODIFYING ', :italic], dst
          FileUtils.mkdir_p File.dirname(dst), fopts
          FileUtils.touch dst, fopts
          # No simple way to deny FS access to the proc
          if options.noop
            log "Skipping modification procedure for #{dst}"
          else
            prc.call dst
          end
        end

        true

      rescue StandardError => e
        if did_archive
          log ['!! ', :red, :bold], "Rolling back to archive #{archive_path.inspect}"
          restore
        end
        raise e

      ensure
        # Restore original umask
        File.umask old_umask

        # Restore default signal handlers
        %w[INT TERM QUIT].each do |sig|
          trap sig, 'DEFAULT'
        end
      end
    end

    def executed?
      @executed
    end

    def archive
      %w[tar gzip].each do |cmd|
        raise "#{cmd.inspect} not found" unless system "command -v #{cmd} &>/dev/null"
      end

      files = targets(:archive).map { |f| f.sub %r{\A/}, '' }
      return nil if files.empty?

      Dir.chdir '/' do
        if system *(%W[tar zcf #{archive_path}] + files)
          FileUtils.chmod 0600, archive_path
        else
          raise "Archive to #{archive_path.inspect} failed"
        end
      end

      archive_path
    end

    def restore
      Dir.chdir '/' do
        # NOTE: `tar xp` is not POSIX; we'll see how that shakes out
        v = 'v' unless options.quiet
        system *%W[tar z#{v}xpf #{archive_path}]
      end
    end

    # Ask user for confirmation.
    # Returns true without prompting if the `force` or `noop` options are set.
    # Returns true without prompting if no jobs are queued.
    # Returns false without prompting if the `quiet` option is set
    # Returns false without prompting if input is not a tty.
    def tty_confirm?
      return true if options.force or options.noop or targets.empty?
      return false if options.quiet or not $stdin.tty?

      [:create, :modify, :overwrite, :delete].each do |action|
        fs = targets action
        next if fs.empty?
        puts "#{action.to_s.upcase}:\n" + fs.map { |f| ' '*4 + f }.join("\n")
      end

      unless targets(:archive).empty?
        puts "\nAll original links and files will be archived to:\n    #{archive_path}"
      end

      print "\nPermission to continue? [Y/n] "

      # Hack to get a single character from the terminal
      if system 'command -v stty &>/dev/null && stty -a &>/dev/null'
        begin
          system 'stty raw -echo'
          puts (c = $stdin.getc.chr rescue false) # Old ruby returns integer
          !!(c =~ /y|\r|\n/i)
        ensure
          system 'stty -raw echo'
          puts
        end
      else
        !!($stdin.readline.chomp =~ /\A(y|ye|yes)?\z/i) rescue false
      end
    end

    private

    def log *args
      options.logger.log *args unless options.quiet
    end

    def relpath src, dst
      Pathname.new(src).relative_path_from(Pathname.new File.dirname(dst)).to_s
    end

    def linked? src, dst
      (options.relative ? relpath(src, dst) : src) == File.readlink(dst)
    end

    # Compare two files:
    # Returns false if both files have the same inode
    # Returns false if files are of different types
    # Returns false if both are symlinks and have different sources
    # Returns false if both are directories and have different contents
    # Returns false if both are regular files and have different bits
    # Returns true otherwise
    def duplicates? a, b
      astat, bstat = File.lstat(a), File.lstat(b)

      return false if astat.ino == bstat.ino
      return false if astat.ftype != bstat.ftype

      case astat.ftype
      when 'link'
        File.readlink(a) == File.readlink(b)
      when 'directory'
        # Dir::entries just calls readdir(3), so we filter the dot directories
        as, bs = [a, b].map do |dir|
          Dir.entries(dir).sort.reject { |f| f == '.' || f == '..' }.map { |f| File.join dir, f }
        end

        as.zip(bs).each do |a1, b1|
          # File stream must match in name as well as content
          return false if File.basename(a1) != File.basename(b1)
          return false if not duplicates? a1, b1
        end

        true
      else
        FileUtils.identical? a, b
      end
    end
  end
end
