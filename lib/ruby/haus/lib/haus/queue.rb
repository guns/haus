# -*- encoding: utf-8 -*-

require 'fileutils'
require 'ostruct'

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
  # is extracted in an attempt to restore the previous state.
  #
  class Queue
    class MultipleJobError < RuntimeError; end

    include FileUtils

    attr_reader :options, :archive_path
    attr_reader :links, :copies, :modifications, :deletions

    def initialize opts = nil
      self.options = opts || OpenStruct.new

      @links, @copies, @modifications, @deletions = (1..4).map { [].freeze }

      # NOTE: Array#shuffle and Enumerable#take introduced in 1.8.7
      time, salt = Time.now.strftime('%s'), ('a'..'z').sort_by { rand }[0..7].join
      @archive_path = "/tmp/haus-#{time}-#{salt}.tar.gz".freeze
    end

    # Dups and freezes object for safety
    def options= opts
      @options = opts.dup.freeze if opts
    end

    # Add symlinking operation;
    # noop if src does not exist or dst already points to src
    def add_link source, destination
      src, dst = [source, destination].map { |f| File.expand_path f }

      raise MultipleJobError if targets.include? dst
      return nil unless File.exists? src
      return nil if File.symlink? dst and File.expand_path(File.readlink dst) == src

      @links = (links.dup << [src,dst]).freeze
    end

    # Add copy operation;
    # noop if src does not exist or src and dst contain the same bits
    def add_copy source, destination
      src, dst = [source, destination].map { |f| File.expand_path f }

      raise MultipleJobError if targets.include? dst
      return nil unless File.exists? src
      return nil if File.exists? dst and cmp src, dst

      @copies = (copies.dup << [src, dst]).freeze
    end

    # Add deletion operation;
    # noop if dst does not exist
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
    #   q.add_modification 'smilies.txt' do |file|
    #     File.open(file, 'a') { |f| f.puts ':)' }
    #   end
    #
    # NOTE: The passed block should not assume that the passed file exists.
    #
    def add_modification destination, &block
      dst = File.expand_path destination

      raise MultipleJobError if targets.include? dst
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
      # Left over: extant files that will be wholly replaced by links and copies
      when :overwrite then targets - targets(:create) - targets(:modify) - targets(:delete)
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

      archive

      begin
        # Rollback on signals
        %w[INT TERM QUIT].each do |sig|
          trap(sig) { raise "Caught signal SIG#{sig}" }
        end

        opts = { :noop => options.noop, :verbose => options.quiet ? false : options.verbose }
        deletions.each     { |d|   rm_rf d, opts.merge(:secure => true) }
        links.each         { |s,d| ln_sf s, d, opts }
        copies.each        { |s,d| cp_r  s, d, opts.merge(:preserve => true, :remove_destination => true) }
        modifications.each { |p,d| p.call d }

      rescue StandardError => e
        warn "!! Rolling back to archive #{archive_path.inspect}"
        restore
        raise e

      ensure
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

      chdir '/' do
        files = (targets - targets(:create)).map { |f| f.sub %r{\A/}, '' }
        unless system *(%W[tar zcf #{archive_path}] + files)
          raise "Archive to #{archive_path.inspect} failed"
        end
      end

      archive_path
    end

    def restore
      chdir '/' do
        # NOTE: `tar xp' is not POSIX; we'll see how that shakes out
        system *%W[tar z#{options.quiet ? '' : 'v'}xpf #{archive_path}]
      end
    end

    # Ask user for confirmation.
    # Returns true if the `force' or `noop' options are set.
    # Returns true if no jobs are queued.
    # Returns false if input is not a tty.
    def tty_confirm?
      return true if options.force or options.noop
      return true if targets.empty?
      return false if not $stdin.tty?

      [:create, :modify, :overwrite, :delete].each do |action|
        fs = targets action
        next if fs.empty?
        puts "#{action.to_s.upcase}:\n" + fs.map { |f| ' '*4 + f }.join("\n")
      end

      puts "\nAll original links and files will be archived to:\n    #{archive_path}"
      print 'Permission to continue? [Y/n] '

      # Hack to get a single character from the terminal
      if system 'command -v stty &>/dev/null && stty -a &>/dev/null'
        begin
          system 'stty raw -echo'
          puts (c = $stdin.getc.chr rescue false) # Old ruby returns integer
          !!(c =~ /y|\n/i)
        ensure
          system 'stty -raw echo'
          puts
        end
      else
        !!($stdin.readline =~ /\A(\n|y\n|ye\n|yes\n)\z/i) rescue false
      end
    end
  end
end
