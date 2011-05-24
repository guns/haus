# -*- encoding: utf-8 -*-

require 'fileutils'

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

    attr_reader :links, :copies, :modifications, :deletions, :archive_path

    def initialize
      @links, @copies, @modifications, @deletions = (1..4).map { [].freeze }

      # NOTE: Array#shuffle and Enumerable#take introduced in 1.8.7
      time, salt = Time.now.strftime('%s'), ('a'..'z').sort_by { rand }[0..7].join
      @archive_path = "/tmp/haus-#{time}-#{salt}.tar.gz".freeze
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

    def targets action = :all
      case action
      when :all       then (links + copies + modifications).map { |s,d| d } + deletions
      when :create    then targets.reject { |f| File.exists? f }
      when :modify    then modifications.map { |p,d| d } - targets(:create)
      when :overwrite then (links + copies).map { |s,d| d }.select { |f| File.file? f }
      when :delete    then deletions
      end
    end

    # Ask user for confirmation;
    # Returns false if input is not a tty or the `stty' program is not available;
    # Returns true if no changes will be made
    def tty_confirm?
      return false if not $stdin.tty?
      return true if targets.empty?

      [:create, :modify, :overwrite, :delete].each do |action|
        fs = targets action
        next if fs.empty?
        puts "#{action.to_s.upcase}:\n" + fs.map { |f| ' '*4 + f }.join("\n")
      end

      puts "\nAll original links and files will be archived to:\n    #{archive_path}"
      print 'Permission to continue? [Y/n] '

      # Hack to get a single character from the terminal
      if system 'command -v stty &>/dev/null'
        begin
          system 'stty raw -echo'
          puts (c = $stdin.getc.chr) # Old ruby returns integer
          c =~ /y|\n/i
        ensure
          system 'stty -raw echo'
          puts
        end
      else
        $stdin.readline =~ /\n|y\n|ye\n|yes\n/i rescue nil
      end
    end
  end
end
