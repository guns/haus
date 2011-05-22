# -*- encoding: utf-8 -*-

require 'fileutils'

class Haus
  #
  # Instead of executing filesystem calls immediately, Haus::Task instances
  # register actions via Queue#add_*, which can then be executed after user
  # confirmation.
  #
  # Any files that would be overwritten, modified, or removed are saved to a
  # tarball in /tmp/
  #
  class Queue
    include FileUtils

    attr_reader :links, :copies, :modifications, :deletions, :archive_path

    def initialize
      @links, @copies, @modifications, @deletions = [], [], [], []

      # NOTE: Array#shuffle and Enumerable#take introduced in 1.8.7
      time, salt = Time.now.strftime('%s'), ('a'..'z').sort_by { rand }[0..7].join
      @archive_path = "/tmp/haus-#{time}-#{salt}.tar.gz"
    end

    # Add symlinking operation;
    # noop if src does not exist or dst already points to src
    def add_link src, dst
      if not File.exists? src
        self
      elsif File.symlink? dst and File.expand_path(File.readlink dst) == File.expand_path(src)
        self
      else
        links << [src, dst].map { |f| File.expand_path f }
        self
      end
    end

    # Add copy operation; noop if src and dst contain the same bits
    def add_copy src, dst
      if not File.exists? src
        self
      elsif File.exists? dst and cmp src, dst
        self
      else
        copies << [src, dst].map { |f| File.expand_path f }
        self
      end
    end

    # Add modification operation; first paramater is a Proc object that
    # takes one file, dst, as a parameter:
    #
    #   q = Queue.new
    #   add_smiley = lambda { |f| File.open(f, 'a') { |f| f.puts ':)' } }
    #   q.add_modification add_smiley, 'smilies.txt'
    #
    # NOTE: The Proc handler should not assume that the passed file exists.
    #
    def add_modification prc, dst
      modifications << [prc, File.expand_path(dst)]
      self
    end

    # Add deletion operation; noop if dst does not exist
    def add_deletion dst
      if not File.exists? dst
        self
      else
        deletions << File.expand_path(dst)
        self
      end
    end

    def targets action = :all
      case action
      when :all       then (links + copies + modifications).map { |s,d| d } + deletions
      when :create    then targets.select { |f| not File.exists? f }
      when :modify    then modifications.map { |p,d| d } - targets(:create)
      when :overwrite then (links + copies).map { |s,d| d }.select { |f| File.file? f }
      when :delete    then deletions
      end
    end

    # Ask user for confirmation;
    # Returns false if input is not a tty or the `stty' program is not available;
    # Returns true if no changes will be made
    def tty_confirm?
      return false if not $stdin.tty? or not system 'command -v stty &>/dev/null'
      return true if targets.empty?

      [:create, :modify, :overwrite, :delete].each do |action|
        fs = targets action
        next if fs.empty?
        puts "#{action.to_s.upcase}:\n" + fs.map { |f| ' '*4 + f }.join("\n")
      end

      puts "\nAll original links and files will be archived to:\n    #{archive_path}\n"
      print 'Permission to continue? [Y/n] '

      # Hack to get a single character from the terminal
      begin
        system 'stty raw -echo'
        puts (c = $stdin.getc.chr)
        c =~ /y|\s/i # [Y|y|\r|\n]
      ensure
        system 'stty -raw echo'
        puts
      end
    end
  end
end
