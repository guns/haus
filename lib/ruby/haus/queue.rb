# -*- encoding: utf-8 -*-

require 'etc'
require 'fileutils'
require 'ostruct'
require 'pathname'
require 'haus/logger'
require 'haus/ls_colors'
require 'haus/utils'

class Haus
  #
  # Instead of executing filesystem calls immediately, Haus::Task instances
  # register jobs via Queue#add_*, which can then be executed after optional
  # user confirmation.
  #
  # For safety, the individual job queues are frozen; jobs should be removed
  # from the queue via Queue#remove. In addition, multiple jobs are not
  # allowed to be queued for a single destination, and options cannot be
  # modified while the queue is being executed.
  #
  # Before execution, any files that would be overwritten, modified, or
  # removed are saved to an archive. If an error is raised during execution,
  # the archive is extracted in an attempt to restore the previous state
  # (however, no attempt is made to remove any newly created files).
  #
  class Queue
    MultipleJobError = Class.new RuntimeError

    attr_reader :options, :archive_path, :links, :copies, :modifications, :deletions, :annotations

    def initialize opts = nil
      self.options = opts || OpenStruct.new
      options.logger ||= Haus::Logger.new

      @links, @copies, @modifications, @deletions = (1..4).map { [].freeze }
      @annotations = {}.freeze

      # Array#shuffle and Enumerable#take unavailable in 1.8.6
      time = Time.now.strftime '%Y-%m-%d.%H-%M-%S.%N'
      @archive_path = "/tmp/haus-#{time}.tar.gz".freeze
    end

    # Parameter can be a Hash or an OpenStruct;
    def options= opts
      @options = opts.is_a?(Hash) ? OpenStruct.new(opts) : opts.dup
    end

    # Add symlinking operation;
    # noop if source does not exist or destination already points to source
    def add_link source, destination
      src, dst = [source, destination].map { |f| File.expand_path f }

      raise MultipleJobError if include? dst
      return nil unless extant? src
      raise_if_blocking_path dst
      return nil if File.symlink? dst and linked? src, dst

      @links = (links.dup << [src, dst]).freeze
    end

    # Add copy operation;
    # noop if source does not exist or source and destination are copies
    def add_copy source, destination
      src, dst = [source, destination].map { |f| File.expand_path f }

      raise MultipleJobError if include? dst
      return nil unless extant? src
      raise_if_blocking_path dst
      return nil if extant? dst and duplicates? src, dst

      @copies = (copies.dup << [src, dst]).freeze
    end

    # Add deletion operation;
    # noop if destination does not exist
    def add_deletion destination
      dst = File.expand_path destination

      raise MultipleJobError if include? dst
      return nil unless extant? dst

      @deletions = (deletions.dup << dst).freeze
    end

    # Add modification operation.
    #
    # Parameter is the file to be modified, block is the actual operation,
    # which in turn takes the file to be modified as an argument.
    #
    # The file parameter need not exist, and may be any kind of file type
    # (including directories). Correspondingly, no effort is made to create
    # the file before passing it to the block, although the path to the file's
    # parent directory will be created if missing.
    #
    #   q = Queue.new
    #   q.add_modification 'smilies.txt' do |path|
    #     File.open(path, 'a') { |f| f.puts ':)' }
    #   end
    #
    def add_modification destination, &block
      dst = File.expand_path destination

      raise MultipleJobError if include? dst
      raise_if_blocking_path dst
      return nil if block.nil?

      @modifications = (modifications.dup << [block, dst]).freeze
    end

    # Add a one-line annotation for a destination to be displayed during
    # `tty_confirm?`; overwrites any previous annotations for the same file.
    #
    # Message arguments are passed directly to Haus::Logger#fmt
    def annotate destination, *args
      dst = File.expand_path destination
      @annotations = annotations.merge(dst => args).freeze
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

    def include? file
      targets.include? file
    end

    def hash
      (links + copies + modifications + deletions).hash
    end

    # Remove jobs by destination path; boolean return
    def remove destination
      h = hash

      dst            = File.expand_path destination
      @links         = links.reject { |s,d| d == dst }.freeze
      @copies        = copies.reject { |s,d| d == dst }.freeze
      @modifications = modifications.reject { |s,d| d == dst }.freeze
      @deletions     = deletions.reject { |d| d == dst }.freeze

      hash != h
    end

    # Execute jobs after user confirmation.
    def execute
      execute! if tty_confirm?
    end

    # Execute jobs immediately. Returns true, or raises exceptions.
    #
    # Modifications are processed last.
    def execute!
      # Guard against multiple executions
      return nil if executed?
      @executed = true

      begin
        # Freeze options for safety
        options.freeze

        # Rollback on signals
        %w[INT TERM QUIT].each do |sig|
          trap(sig) { raise "Caught signal SIG#{sig}" }
        end

        did_archive = archive unless options.noop
        old_umask   = File.umask options.umask if options.umask
        fopts       = { :noop => options.noop, :verbose => options.debug }

        execute_deletions     fopts.dup
        execute_links         fopts.dup
        execute_copies        fopts.dup
        execute_modifications fopts.dup

        true

      rescue StandardError => e
        if did_archive
          log ['!! ', :red, :bold], "Rolling back to archive #{archive_path.inspect}"
          restore
        end
        raise e

      ensure
        # Unfreeze options
        @options = options.dup

        # Restore original umask if it was changed
        File.umask old_umask if options.umask

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
        raise "#{cmd.inspect} not found" unless system "/bin/sh -c 'command -v #{cmd}' >/dev/null 2>&1"
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
        log # \n for clarity
      end
    end

    # Ask user for confirmation.
    # Returns true without prompting if the `force` or `noop` options are set.
    # Returns true without prompting if no jobs are queued.
    # Returns false without prompting if the `quiet` option is set
    # Returns false without prompting if input is not a tty.
    #
    # NOTE: Output is to $stdout, not through the logger.
    def tty_confirm?
      return true  if options.force or options.noop or targets.empty?
      return false if options.quiet or not $stdin.tty?

      # Summarize actions
      summary_table.each do |job|
        next if job[:files].empty?
        $stdout.puts fmt(job[:title])
        job[:files].each do |f, note|
          $stdout.puts fmt(' '*4, *f)
          $stdout.puts fmt(' '*7, *note) if note
        end
      end

      # Reassure the user
      unless targets(:archive).empty?
        $stdout.puts "\nAll original links and files will be archived to:\n    #{archive_path}"
      end

      # Prompt and read input
      $stdout.print "\nPermission to continue? [Y/n] "
      response = !!(tty_getchar =~ /\A(y|ye|yes\s*)?\z/i)

      # Pad output with a newline if we have confirmation
      $stdout.puts if response

      response
    end

    # Returns a table of actions with annotated targets
    def summary_table
      [
        [:create,    :green,  '++ '],
        [:modify,    :cyan,   '+- '],
        [:overwrite, :yellow, '-+ '],
        [:delete,    :red,    '-- ']
      ].map do |type, color, prefix|
        files = targets(type).map do |f|
          ft = if type == :create
            if links.any? { |s,d| d == f }
              :link
            # Copy targets are the same type as their sources
            elsif copy = copies.find { |s,d| d == f }
              Haus::LSColors.ftype(copy.first)
            # Modification operations can create anything
            else
              :unknown
            end
          else
            Haus::LSColors.ftype f
          end

          [
            [[prefix, color, :bold], [f, Haus::LSColors[ft]]],
            annotations[f]
          ]
        end

        {
          :title => [type.to_s.upcase + ':', color, :bold],
          :files => files
        }
      end
    end

    # Checks to see if file exists, even broken symlinks
    def extant? path
      File.lstat(path) ? true : false
    rescue Errno::ENOENT
      false
    end

    private

    def log *args
      options.logger.log *args unless options.quiet
    end

    def fmt *args
      options.logger.fmt *args
    end

    # Compare the results of File.readlink(dst) directly to enable switching
    # link styles
    def linked? src, dst
      File.readlink(dst) == (options.relative ? Haus::Utils.relpath(src, dst) : src)
    end

    # Compare two files:
    # Returns false if both files have the same inode
    # Returns false if files are of different types
    # Returns false if both are symlinks and have different sources
    # Returns false if both are directories and have different contents
    # Returns false if both are regular files and have different bits
    # Returns true otherwise
    def duplicates? alpha, beta
      a,     b     = File.expand_path(alpha), File.expand_path(beta)
      astat, bstat = File.lstat(a),           File.lstat(b)

      return false if astat.ino == bstat.ino
      return false if astat.ftype != bstat.ftype

      case astat.ftype
      when 'link'
        # Expand relative links before comparing
        asrc, bsrc = [a, b].map { |f| Haus::Utils.readlink f }
        asrc == bsrc
      when 'directory'
        # Dir::entries just calls readdir(3), so we filter the dot directories
        as, bs = [a, b].map do |dir|
          Dir.entries(dir).sort.reject { |f| f == '.' || f == '..' }.map { |f| File.join dir, f }
        end

        as.zip(bs).each do |af, bf|
          # File stream must match in name as well as content
          return false if File.basename(af) != File.basename(bf)
          return false if not duplicates? af, bf # Recurse!
        end

        true
      else
        FileUtils.identical? a, b
      end
    end

    # Returns the subpath of a path that is assumed to be a tree node, but is
    # not actually a directory or a link to one. Returns nil otherwise.
    def blocking_path path
      Pathname.new(path).descend do |p|
        # Don't evaluate the leaf
        break if p.to_s == path

        return nil    if not extant? p.to_s
        return p.to_s if not p.directory?
      end

      nil
    end

    def raise_if_blocking_path path
      bp = blocking_path path
      raise "#{bp.inspect} would block the creation of #{path.inspect}" if bp
    end

    def create_path_to file, fopts
      parent = File.dirname file
      if not extant? parent
        create_path_to parent, fopts # Recurse!
        FileUtils.mkdir parent, **fopts
        adopt parent, fopts
      end
    end

    # Change the uid and gid of the file to match its parent directory.
    # Parent directory must exist.
    def adopt file, fopts
      # Some old versions of FileUtils#chown_R only accept user names, so we
      # must do the passwd lookup here.
      p     = File.lstat File.dirname(file)
      user  = Etc.getpwuid(p.uid).name
      group = Etc.getgrgid(p.gid).name

      case File.lstat(file).ftype
      when 'directory'
        FileUtils.chown_R user, group, file, **fopts
      else
        # FileUtils logs to $stderr when verbose
        $stderr.puts 'chown -h %s:%s %s' % [user, group, file] if fopts[:verbose]
        File.lchown p.uid, p.gid, file unless fopts[:noop]
      end
    end

    def execute_deletions fopts
      deletions.each do |dst|
        log ['-- DELETING ', :red, :italic], [dst, Haus::LSColors[dst]]
        FileUtils.rm_r dst, **fopts.merge(:secure => true)
      end
    end

    def execute_links fopts
      links.each do |src, dst|
        srcpath = options.relative ? Haus::Utils.relpath(src, dst) : src

        # NOTE: utf8 char
        prefix = extant?(dst) ? ['-+ LINKING ', :yellow, :italic] : ['++ LINKING ', :green, :italic]
        srcfmt = [srcpath, Haus::LSColors[src]]
        dstfmt = [dst, Haus::LSColors[:link]]
        log prefix, srcfmt, ' → ', dstfmt

        FileUtils.rm_r dst, **fopts.merge(:secure => true) if extant? dst
        create_path_to dst, fopts

        FileUtils.ln_s srcpath, dst, **fopts
        adopt dst, fopts
      end
    end

    def execute_copies fopts
      copies.each do |src, dst|
        prefix   = extant?(dst) ? ['-+ COPYING ', :yellow, :italic] : ['++ COPYING ', :green, :italic]
        srcstyle = Haus::LSColors[src]
        srcfmt   = [src, srcstyle]
        dstfmt   = [dst, srcstyle]
        log prefix, srcfmt, ' → ', dstfmt

        FileUtils.rm_r dst, **fopts.merge(:secure => true) if extant? dst
        create_path_to dst, fopts

        # Ruby 1.9's copy implementation breaks on broken symlinks
        if File.ftype(src) == 'link'
          lsrc = File.readlink src
          # Leave absolute paths alone, but recalculate relative paths
          srcpath = lsrc[0] == '/' \
                    ? lsrc \
                    : Haus::Utils.relpath(File.expand_path(lsrc, File.join(src, '..')), dst)
          FileUtils.ln_s srcpath, dst, **fopts
        else
          # NOTE: Explicit :dereference_root option required for 1.8.6
          FileUtils.cp_r src, dst, **fopts.merge(:dereference_root => false)
        end

        adopt dst, fopts
      end
    end

    def execute_modifications fopts
      modifications.each do |prc, dst|
        if extant? dst
          log ['+- MODIFYING ', :cyan, :italic], [dst, Haus::LSColors[dst]]
        else
          log ['++ CREATING ', :green, :italic], dst
        end

        create_path_to dst, fopts

        # No simple way to deny FS access to the proc
        if options.noop
          log "Skipping modification procedure for #{dst}"
        else
          prc.call dst
        end

        # The proc may not actually create dst
        adopt dst, fopts if extant? dst
      end
    end

    # Get a single char (or line if unsupported) from $stdin; input is sent
    # String#chomp before being returned.
    #
    # Returns nil on error.
    def tty_getchar
      # `stty -a` will return non-zero when not run from a terminal
      if system '/bin/sh -c "command -v stty && stty -a" >/dev/null 2>&1'
        begin
          # `stty` man page says that toggling the raw bit is not guaranteed
          # to restore previous state, so we should do that explicitly
          state = %x(stty -g).chomp
          system 'stty', 'raw'
          char = $stdin.getc.chr.chomp rescue nil # Ruby 1.8.* returns Integer
        ensure
          system 'stty', state
          $stdout.puts char
        end
      else
        $stdin.readline.chomp rescue nil
      end
    end
  end
end
