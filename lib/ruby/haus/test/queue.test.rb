# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'fileutils'
require 'ostruct'
require 'expect'
require 'stringio'
require 'tempfile'
require 'haus/queue'
require 'haus/logger'
require 'haus/test/helper/minitest'
require 'haus/test/helper/test_user'
require 'haus/test/helper/noop_tasks'

$user ||= Haus::TestUser[$$]

class Haus::QueueSpec < MiniTest::Spec
  it 'must contain some error classes' do
    Haus::Queue.constants.map { |c| c.to_s }.sort.must_equal %w[MultipleJobError]
  end

  before do
    @q = Haus::Queue.new :quiet => true
  end

  describe :initialize do
    it 'must optionally accept an OpenStruct or Hash object and create the options object' do
      logger = Haus::Logger.new
      @q.method(:initialize).arity.must_equal -1

      queue = Haus::Queue.new
      queue.options.must_be_kind_of OpenStruct
      queue.options.logger.must_be_kind_of Haus::Logger
      queue.options.frozen?.must_equal false

      [Haus::Queue.new(OpenStruct.new :force => true), Haus::Queue.new(:force => true)].each do |q|
        q.options.must_be_kind_of OpenStruct
        q.options.force.must_equal true
        q.options.logger.must_be_kind_of Haus::Logger
      end
    end

    it 'must initialize the attr_readers, which should be frozen' do
      %w[links copies modifications deletions].each do |m|
        @q.send(m).must_equal []
        @q.send(m).frozen?.must_equal true
      end

      @q.annotations.must_equal Hash.new
      @q.annotations.frozen?.must_equal true

      @q.archive_path.must_match %r{\A/tmp/haus-\d+-\d+-\d+-[a-z]+\.tar\.gz\z}
      @q.archive_path.frozen?.must_equal true
    end
  end

  describe :options= do
    it 'must dup and store an OpenStruct parameter' do
      os = OpenStruct.new :foo => 'foo', :bar => 'bar'
      @q.options = os
      @q.options.must_be_kind_of OpenStruct
      @q.options.foo.must_equal 'foo'
      os.foo = 'MOO'
      os.foo.must_equal 'MOO'
      @q.options.foo.must_equal 'foo'
    end

    it 'must accept a Hash parameter' do
      h = { :sniffy => 'nose', :stinky => 'butt' }
      @q.options = h
      @q.options.must_be_kind_of OpenStruct
      @q.options.sniffy.must_equal 'nose'
      h[:sniffy] = 'toes'
      @q.options.sniffy.must_equal 'nose'
    end

    it 'must raise RuntimeError if the options object is frozen' do
      lambda { @q.options = { :foo => 'foo' }; raise StandardError }.must_raise StandardError
      @q.options.freeze
      lambda { @q.options[:foo] = 'bar' }.must_raise RuntimeError
    end
  end

  describe :add_link do
    it 'must noop and return nil when src does not exist' do
      @q.add_link('/foo/bar/with/baz', "#{$user.dir}/baz").must_be_nil
      @q.links.empty?.must_equal true
    end

    it 'must noop and return nil when dst points to src' do
      src, dst = $user.hausfile
      FileUtils.ln_s src, dst
      @q.add_link(src, dst).must_be_nil
      @q.links.empty?.must_equal true
    end

    it 'must raise an error when a job for dst already exists' do
      args = $user.hausfile
      @q.add_link *args
      lambda { @q.add_link *args }.must_raise Haus::Queue::MultipleJobError
    end

    it 'must raise an error if argument has a blocking path' do
      assert_raises RuntimeError do
        @q.add_copy File.join($user.etc), File.join($user.hausfile.first, 'illegal')
      end
    end

    describe :success do
      before do
        # NOTE: We cannot pass a block (implicitly or explicitly) to a Proc in
        #       1.8.6, so we pass a Proc instead
        @assertion = lambda do |prc, qopts|
          q = Haus::Queue.new qopts || {}
          src, dst = $user.hausfile
          prc.call src, dst
          res = q.add_link src, dst
          res.must_equal [[src, dst]]
          res.frozen?.must_equal true
          q.links.must_equal [[src, dst]]
          q.links.frozen?.must_equal true
        end
      end

      it 'must push and refreeze @links when src does exist and dst does not point to src' do
        @assertion.call lambda { |src, dst| FileUtils.ln_s '/etc/passwd', dst }, nil
      end

      it 'must add existing links if relative/absolute prefs do not match' do
        @assertion.call lambda { |src, dst|
          FileUtils.ln_sf relpath(src, dst), dst
        }, nil

        @assertion.call lambda { |src, dst|
          FileUtils.ln_sf src, dst
        }, :relative => true
      end

      it 'must remove the destination before linking' do
        @assertion.call lambda { |src, dst|
          FileUtils.mkdir_p File.join(dst, 'baz')
          FileUtils.touch File.join(dst, 'baz', 'bar')
        }, nil
      end

      it 'must add links that point to non-extant files' do
        @assertion.call lambda { |src, dst|
          FileUtils.ln_sf '/foo/bar/land', src # Change source to broken symlink
        }, nil
      end
    end
  end

  describe :add_copy do
    it 'must noop and return nil when src does not exist' do
      @q.add_copy('/foo/bar/with/baz', "#{$user.dir}/baz").must_be_nil
      @q.copies.empty?.must_equal true
    end

    it 'must noop and return nil when src and dst equal' do
      src, dst = $user.hausfile
      FileUtils.cp src, dst
      @q.add_copy(src, dst).must_be_nil
      @q.copies.empty?.must_equal true
    end

    it 'must raise an error when a job for dst already exists' do
      args = $user.hausfile
      @q.add_copy *args
      lambda { @q.add_copy *args }.must_raise Haus::Queue::MultipleJobError
    end

    it 'must not add broken but identical symlinks' do
      fs = $user.hausfile
      fs.each { |f| FileUtils.ln_sf '/new/world/bar', f }
      res = @q.add_copy *fs
      res.must_be_nil
      @q.copies.must_be_empty
    end

    it 'must not add relative links that resolve to the same location' do
      src, dst = $user.hausfile
      linksrc  = $user.hausfile.first
      FileUtils.ln_sf relpath(linksrc, src), src
      FileUtils.ln_sf relpath(linksrc, dst), dst
      @q.add_copy(src, dst).must_be_nil
      @q.copies.must_be_empty
    end

    it 'must raise an error if argument has a blocking path' do
      assert_raises RuntimeError do
        @q.add_copy File.join($user.etc), File.join($user.hausfile.first, 'illegal')
      end
    end

    describe :success do
      before do
        @assertion = lambda do |prc|
          q = Haus::Queue.new
          src, dst = $user.hausfile
          prc.call src, dst
          res = q.add_copy src, dst
          res.must_equal [[src, dst]]
          res.frozen?.must_equal true
          q.copies.must_equal [[src, dst]]
          q.copies.frozen?.must_equal true
        end
      end

      it 'must push and refreeze @copies when src exists and dst does not equal src' do
        @assertion.call lambda { |src, dst| File.open(dst, 'w') { |f| f.write dst } }
        @assertion.call lambda { |src, dst|
          File.open(src, 'w') { |f| f.write 'foo' }
          File.open(dst, 'w') { |f| f.write 'bar' }
        }
      end

      it 'must push and refreeze @copies when src and dst are of different types' do
        @assertion.call lambda { |src, dst| FileUtils.mkdir_p dst }
      end

      it 'must break hard links' do
        @assertion.call lambda { |src, dst|
          File.open(src, 'w') { |f| f.write 'hard' }
          FileUtils.ln src, dst
        }
      end

      it 'must recurse and compare directory contents of dst to determine whether to copy' do
        @assertion.call lambda { |src, dst|
          FileUtils.rm_f src
          FileUtils.mkdir_p [src, dst]
          File.open("#{src}/bar", 'w') { |f| f.write 'BAR!' }
          File.open("#{dst}/bar", 'w') { |f| f.write 'BAZ!' }
        }
      end

      it 'must remove destination before copying' do
        @assertion.call lambda { |src, dst| File.open(dst, 'w') { |f| f.write dst } }
        @assertion.call lambda { |src, dst|
          FileUtils.mkdir_p File.join(dst, 'baz')
          FileUtils.touch File.join(dst, 'baz', 'bar')
        }
      end

      it 'must copy symlinks as is' do
        @assertion.call lambda { |src, dst| FileUtils.ln_sf '/etc/passwd', src }
        @assertion.call lambda { |src, dst| FileUtils.ln_sf '/foo/bar/rides', src }
      end
    end
  end

  describe :add_deletion do
    it 'must noop and return nil when dst does not exist' do
      @q.add_deletion('/foo/bar/with/baz/quux').must_be_nil
      @q.deletions.empty?.must_equal true
    end

    it 'must push and refreeze @deletions when dst exists' do
      src = $user.hausfile.first
      res = @q.add_deletion src
      res.must_equal [src]
      res.frozen?.must_equal true
      @q.deletions.must_equal [src]
      @q.deletions.frozen?.must_equal true
    end

    it 'must push and refreeze @deletions when dst is a broken symlink' do
      src = $user.hausfile[1]
      FileUtils.ln_sf '/broken/link', src
      res = @q.add_deletion src
      res.must_equal [src]
      res.frozen?.must_equal true
      @q.deletions.must_equal [src]
      @q.deletions.frozen?.must_equal true
    end

    it 'must raise an error when a job for dst already exists' do
      src = $user.hausfile.first
      @q.add_deletion src
      lambda { @q.add_deletion src }.must_raise Haus::Queue::MultipleJobError
    end
  end

  describe :add_modification do
    it 'must noop and return nil when no block is given' do
      @q.add_modification("#{$user.dir}/.ponies").must_be_nil
      @q.modifications.empty?.must_equal true
    end

    it 'must push and return @modifications when a file and block are given' do
      res = @q.add_modification("#{$user.dir}/.ponies") { |f| touch f }
      res.size.must_equal 1
      res.frozen?.must_equal true
      @q.modifications.first[0].respond_to?(:call).must_equal true # must_respond_to, Y U NO WORK?
      @q.modifications.first[1].must_equal "#{$user.dir}/.ponies"
      @q.modifications.frozen?.must_equal true
    end

    it 'must raise an error when a job for dst already exists' do
      src = $user.hausfile.first
      @q.add_modification(src) { |f| touch f }
      lambda { @q.add_modification(src) {} }.must_raise Haus::Queue::MultipleJobError
    end

    it 'must not raise an error if argument is a directory' do
      lambda { @q.add_modification($user.hausfile(:dir).first) {}; raise StandardError }.must_raise StandardError
    end

    it 'must raise an error if argument has a blocking path' do
      lambda { @q.add_modification(File.join $user.hausfile.first, 'illegal') {} }.must_raise RuntimeError
    end
  end

  describe :annotate do
    it 'must add the annotation for the file to the internal table and refreeze' do
      @q.annotate('/foo/bar/baz', ['FUBAR', :red]).must_equal @q.annotations
      @q.annotations['/foo/bar/baz'].must_equal [['FUBAR', :red]]
      @q.annotations.frozen?.must_equal true
    end
  end

  describe :targets do
    # Fill up a queue
    before do
      @files   = (0..8).map { $user.hausfile }
      @sources = @files.map { |s,d| s }
      @targets = @files.map { |s,d| d }

      # Alter some source files
      FileUtils.ln_sf '/nonextant/source', @sources[8]

      # Pre-create targets for some
      [1,3,4,5,7].each { |n| File.open(@targets[n], 'w') { |f| f.puts 'EXTANT' } }

      @files.size.times do |n|
        case n
        when 0..1    then @q.add_link *@files[n]
        when 2..3, 8 then @q.add_copy *@files[n]
        when 4..5    then @q.add_deletion @targets[n]
        when 6..7    then @q.add_modification(@targets[n]) { |f| f }
        end
      end
    end

    it 'must return all targets by default' do
      @q.targets.sort.must_equal @targets.sort
      @q.targets(:all).sort.must_equal @targets.sort
    end

    it 'must return all files to be removed on :delete' do
      @q.targets(:delete).must_equal @targets.values_at(4,5)
    end

    it 'must return all new files on :create' do
      @q.targets(:create).sort.must_equal @targets.values_at(0,2,6,8).sort
    end

    it 'must return all files to be modified on :modify' do
      @q.targets(:modify).must_equal @targets.values_at(7)
    end

    it 'must return all files that will be overwritten on :overwrite' do
      @q.targets(:overwrite).must_equal @targets.values_at(1,3)
    end

    it 'must return all files that should be archived on :archive' do
      @q.targets(:archive).sort.must_equal @targets.select { |f| extant? f }.sort
    end

    it 'must be a complete list of targets with no overlapping entries' do
      [:delete, :create, :modify, :overwrite].inject [] do |a,m|
        a + @q.targets(m)
      end.sort.must_equal @targets.sort
    end
  end

  describe :include? do
    it 'must return true if queue.targets include file' do
      src, dst = $user.hausfile
      @q.include?(dst).must_equal false
      @q.add_link src, dst
      @q.include?(dst).must_equal true
    end
  end

  describe :hash do
    it 'must return a hash of the concatenation of all job queues' do
      files = (0..3).map { $user.hausfile }
      @q.hash.must_equal [].hash
      @q.add_link *files[0]
      @q.add_copy *files[1]
      @q.add_modification(files[2].last) { |f| f }
      @q.add_deletion files[3].first
      @q.hash.must_equal((@q.links + @q.copies + @q.modifications + @q.deletions).hash)
    end
  end

  describe :remove do
    it 'must remove jobs by destination path' do
      files = (0..2).map { $user.hausfile }
      @q.add_link *files[0]
      @q.add_copy *files[1]
      @q.add_modification(files[2].last) { |f| puts f }
      @q.targets.sort.must_equal files.map { |s,d| d }.sort
      @q.remove('/etc/passwd').must_equal false
      @q.remove(files[1].last).must_equal true
      @q.targets.sort.must_equal files.values_at(0,2).map { |s,d| d }.sort
      @q.copies.frozen?.must_equal true
    end
  end

  describe :execute do
    it 'must confirm then call execute!' do
      @q.instance_eval do
        def tty_confirm?
          @_confirmed = true
          super
        end
      end

      @q.instance_variable_get(:@_confirmed).must_equal nil
      @q.add_link *$user.hausfile
      with_no_stdin { @q.execute }
      @q.instance_variable_get(:@_confirmed).must_equal true
    end
  end

  describe :execute! do
    before do
      @q.extend Haus::Unadoptable

      @files   = (0..12).map { $user.hausfile }
      @sources = @files.map { |s,d| s }
      @targets = @files.map { |s,d| d }

      # Alter sources for some
      FileUtils.ln_sf relpath('/etc/passwd', @sources[10]), @sources[10] # Local relative link
      FileUtils.ln_sf File.expand_path(@sources[9]), @sources[11]        # Absolute link
      FileUtils.ln_sf '/yo/yo/ma', @sources[12]                          # Broken link

      # Pre-create targets for some
      [3,4,5].each { |n| File.open(@targets[n], 'w') { |f| f.write 'EXTANT' } }

      @files.size.times do |n|
        case n
        when 0..1, 8..9   then @q.add_link *@files[n]
        when 2..3, 10..12 then @q.add_copy *@files[n]
        when 4..5         then @q.add_deletion @targets[n]
        when 6..7         then
          @q.add_modification @targets[n] do |f|
            File.open(f, 'w') { |io| io.write 'MODIFIED' }
          end
        end
      end
    end

    after do
      FileUtils.rm_f @q.archive_path
    end

    it 'must return nil if already executed' do
      @q.execute!
      @q.executed?.must_equal true
      @q.execute!.must_equal nil
    end

    it 'must create an archive before execution' do
      @q.execute!
      File.exist?(@q.archive_path).must_equal true
    end

    it 'must not create an archive if options.noop is specified' do
      @q.options = { :noop => true, :quiet => true }
      @q.execute!
      File.exist?(@q.archive_path).must_equal false
    end

    it 'must not modify the filesystem if options.noop is specified' do
      q = Haus::Queue.new :noop => true, :quiet => true
    end

    it 'must rollback changes on signals' do
      # Yes, this is a torturous way of testing the rollback function
      %w[INT TERM QUIT].each do |sig|
        target = $user.hausfile.last
        capture_fork_io do
          @q.add_modification target do |f|
            # Delete extant files
            FileUtils.rm_rf @targets, :secure => true
            # This shouldn't print if they're really gone
            print 'foo' if extant? @targets[3]
            print 'bar'
            kill sig, $$
            sleep 1
            # Should not print due to signal
            print 'baz'
          end
          @q.execute!
        end.first.must_equal 'bar'

        # But the rollback should have restored previously extant files
        @targets.select { |f| extant? f }.must_equal @targets.values_at(3,4,5)
      end
    end

    it 'must rollback changes on StandardError' do
      target = $user.hausfile.last

      capture_fork_io do
        @q.add_modification target do |f|
          FileUtils.rm_rf @targets, :secure => true
          print 'foo' if extant? @targets[3]
          print 'bar'
          raise StandardError
          print 'baz'
        end
        @q.execute!
      end.first.must_equal 'bar'

      @targets.select { |f| extant? f }.must_equal @targets.values_at(3,4,5)
    end

    it 'must delete files' do
      [4,5].each { |n| extant?(@targets[n]).must_equal true }
      @q.execute!
      [4,5].each { |n| extant?(@targets[n]).must_equal false }
    end

    it 'must link files' do
      [0,1].each { |n| File.symlink?(@targets[n]).must_equal false }
      @q.execute!
      [0,1].each do |n|
        File.symlink?(@targets[n]).must_equal true
        File.readlink(@targets[n]).must_equal @sources[n]
      end
    end

    it 'must link files with relative source paths when specified' do
      [8,9].each { |n| File.symlink?(@targets[n]).must_equal false }
      opts = @q.options.dup
      opts.relative = true
      @q.options = opts
      @q.execute!
      [8,9].each do |n|
        File.symlink?(@targets[n]).must_equal true
        tgtpath = relpath(@sources[n], @targets[n])
        File.readlink(@targets[n]).must_equal tgtpath
        File.expand_path(File.readlink(@targets[n]), File.dirname(@targets[n])).must_equal @sources[n]
      end
    end

    it 'must copy files' do
      extant?(@targets[2]).must_equal false
      extant?(@targets[3]).must_equal true
      FileUtils.cmp(@sources[3], @targets[3]).must_equal false
      @q.execute!
      [2,3].each { |n| FileUtils.cmp(@sources[n], @targets[n]).must_equal true }
    end

    it 'must copy links, not their sources' do
      src, dst = $user.hausfile :link
      q = Haus::Queue.new :quiet => true, :force => true
      q.extend Haus::Unadoptable
      File.lstat(src).ftype.must_equal 'link'
      q.add_copy src, dst
      q.copies.must_equal [[src, dst]]
      q.execute!
      File.lstat(dst).ftype.must_equal 'link'
    end

    it 'must copy relative links, but recalculate their paths' do
      @q.execute!
      File.lstat(@targets[10]).ftype.must_equal 'link'
      File.readlink(@targets[10]).wont_equal File.readlink(@sources[10])
      File.readlink(@targets[10]).must_equal relpath(File.expand_path(File.readlink(@targets[10]), $user.etc), @sources[10])
    end

    it 'must copy absolute links as is' do
      @q.execute!
      File.lstat(@targets[11]).ftype.must_equal 'link'
      File.readlink(@targets[11]).must_equal File.readlink(@sources[11])
    end

    it 'must copy broken symlinks' do
      extant?(@sources[12]).must_equal true
      @q.copies.must_include @files[12]
      @q.execute!
      File.lstat(@targets[12]).ftype.must_equal 'link'
      File.readlink(@targets[12]).must_equal File.readlink(@sources[12])
    end

    it 'must modify files' do
      [6,7].each { |n| File.open(@targets[n], 'w') { |f| f.write 'CREATED' } }
      @q.execute!
      [6,7].each { |n| File.read(@targets[n]).must_equal 'MODIFIED' }
    end

    it 'must not touch files before calling modification proc' do
      target = $user.hausfile.last
      extant?(target).must_equal false
      @q.add_modification $user.hausfile.last do |f|
        extant?(f).must_equal false
      end
      @q.execute!
    end

    it 'must create parent directories before file creation' do
      begin
        sources = [$user.hausfile, $user.hausfile(:dir), $user.hausfile(:link)].map { |s,d| s }
        targets = sources.map { |f| File.join $user.dir, File.basename(f).reverse, File.basename(f) }
        @q.add_link sources[0], targets[0]
        @q.add_copy sources[1], targets[1]
        @q.add_modification targets[2] do |f|
          File.open(f, 'w') { |io| io.write 'MODIFIED' }
        end
        @q.execute!
        targets.each { |f| extant?(f).must_equal true }
      ensure
        FileUtils.rm_rf targets.map { |f| File.dirname f }
      end
    end

    it 'must create files with options.umask, but should not permanently change the process umask' do
      old_umask = File.umask
      @q.options.umask = 0077
      @q.execute!
      # Symlinks are always mode 0777 on Linux
      # @targets.values_at(0..3, 6..9).each do |f|
      #   (File.lstat(f).mode & 0077).must_equal 0
      # end
      File.umask.must_equal old_umask
    end

    it 'must freeze the options object during execution and unfreeze afterwards' do
      q = Haus::Queue.new :quiet => true
      q.options.frozen?.must_equal false
      opts = q.options.dup
      q.add_modification $user.hausfile[1] do
        q.options.frozen?.must_equal true
      end
      q.options.frozen?.must_equal false
      q.execute!
      q.options.must_equal opts
    end

    it 'must pass :verbose => true to FileUtils ops when options.debug' do
      capture_fork_io do
        $stderr.reopen '/dev/null'
        @q.options.debug = true
        @q.instance_eval do
          def execute_deletions fopts
            puts "Verbose is #{fopts[:verbose].inspect}"
            super
          end
        end
        @q.execute!
      end.first.must_match /\AVerbose is true/
    end

    it 'must raise Errno::EPERM when trying to remove privileged files' do
      # TODO: How can we test this?
    end

    it 'must change the ownership of newly created files to that of its parent' do
      # TODO: How can we test this?
    end
  end

  describe :executed? do
    it 'must return @executed' do
      @q.executed?.must_equal nil
      @q.instance_variable_set :@executed, true
      @q.executed?.must_equal true
    end
  end

  describe :archive do
    before do
      @targets = (0..3).map { $user.hausfile.last }
      FileUtils.touch @targets
      @q.add_link '/etc/passwd', @targets[0]
      @q.add_copy '/etc/passwd', @targets[1]
      @q.add_modification(@targets[2]) {}
      @q.add_deletion @targets[3]
      @q.add_link '/etc/passwd', '/foo/bar/with/baz'
      @q.add_copy '/etc/passwd', '/foo/bar/with/flying/quux'
      @q.add_modification('/foo/bar/in/the/sky') { |f| f }
    end

    after do
      FileUtils.rm_f @q.archive_path
    end

    it 'must raise an error if tar or gzip are not available' do
      begin
        path = ENV['PATH'].dup
        lambda { ENV['PATH'] = ''; @q.archive }.must_raise RuntimeError
      ensure
        ENV['PATH'] = path
      end
    end

    it 'must create an archive of all extant targets' do
      @q.archive
      File.exist?(@q.archive_path).must_equal true
      list = %x(tar tf #{@q.archive_path} 2>/dev/null).split "\n"
      list.sort.must_equal @targets.map { |f| f.sub /\A\//, '' }.sort
    end

    it 'must return the archive path on success' do
      @q.archive.must_equal @q.archive_path
    end

    it 'must return nil when no files are needed to backup' do
      begin
        q = Haus::Queue.new
        q.add_link *$user.hausfile
        q.targets.size.must_equal 1
        q.archive.must_be_nil
      ensure
        FileUtils.rm_f q.archive_path
      end
    end

    it 'must create a regular file with owner-only privileges' do
      @q.archive
      File.lstat(@q.archive_path).mode.must_equal 0100600
    end
  end

  describe :restore do
    before do
      @targets = [$user.hausfile, $user.hausfile(:dir), $user.hausfile(:link)].map { |s,d| d }
      FileUtils.touch @targets
      @q.instance_variable_set :@deletions, @targets
    end

    after do
      FileUtils.rm_f @q.archive_path
    end

    it 'must restore the current archive' do
      @q.archive
      list = %x(tar tf #{@q.archive_path} 2>/dev/null).split("\n").reject do |f|
        f =~ %r{haus-\w+/haus-\w+\z}
      end.map { |f| f.chomp '/' }
      list.sort.must_equal @targets.map { |f| f.sub %r{\A/}, '' }.sort
      FileUtils.rm_rf @targets
      @targets.map { |f| extant? f }.uniq.must_equal [false]
      @q.restore
      @targets.map { |f| extant? f }.uniq.must_equal [true]
    end
  end

  describe :tty_confirm? do
    before do
      @q.add_link *$user.hausfile
    end

    it 'must return true when force is set' do
      with_no_stdin do
        @q.tty_confirm?.must_equal false
        @q.options = { :force => true }
        @q.tty_confirm?.must_equal true
      end
    end

    it 'must return true when noop is set' do
      with_no_stdin do
        @q.tty_confirm?.must_equal false
        @q.options = { :noop => true }
        @q.tty_confirm?.must_equal true
      end
    end

    it 'must return true when queue is clear' do
      with_no_stdin do
        @q.tty_confirm?.must_equal false
        @q.remove @q.targets.first
        @q.tty_confirm?.must_equal true
      end
    end

    it 'must return false when options.quiet is set' do
      with_confirmation = lambda do |prc|
        with_filetty do
          $stdout.expect 'continue? [Y/n] ', 1 do
            $stdin.write "Y\n"
            $stdin.rewind
          end
          prc.call
        end
      end

      with_confirmation.call lambda { @q.options.quiet = false; @q.tty_confirm?.must_equal true }
      with_confirmation.call lambda { @q.options.quiet = true; @q.tty_confirm?.must_equal false }
    end

    it 'must return false when $stdin is not a tty' do
      with_filetty do
        $stdout.expect 'continue? [Y/n] ', 1 do
          $stdin.write "Y\n"
          $stdin.rewind
        end
        @q.options.quiet = false
        @q.tty_confirm?.must_equal true
        $stdin.instance_eval do
          def tty?; false end
          def isatty?; false end
        end
        @q.tty_confirm?.must_equal false
      end
    end

    it 'must request user input from $stdin when from a terminal' do
      @q.options.quiet = false
      %W[\n y\n ye\n yes\n YeS\n n\n no\n nO\n \r \r\n].each do |str|
        with_filetty do
          $stdout.expect 'continue? [Y/n] ', 1 do
            $stdin.write str
            $stdin.rewind
          end
          @q.tty_confirm?.must_equal !!(str =~ /\A(y|\r|\n)/i)
        end
      end
    end

    it 'must print a list of all targets, along with annotations' do
      with_negation = lambda do |prc|
        with_filetty do
          $stdout.expect 'continue? [Y/n] ', 1 do
            $stdin.write "n\n"
            $stdin.rewind
          end
          prc.call
        end
      end

      user, q = Haus::TestUser.new, Haus::Queue.new
      files   = (0..5).map { |n| Tempfile.new(n.to_s).path }

      FileUtils.rm_f files[1]
      File.open(files[3], 'w') { |f| f.puts ':)' }

      q.add_link *files[0..1]
      q.annotate files[1], 'this-is-a-new-file'
      q.add_copy *files[2..3]
      q.add_modification(files[4]) {}
      q.add_deletion files[5]
      q.annotate files[5], ['WARNING', :red], ' deletion'

      with_negation.call lambda {
        q.options.logger.io = $stdout
        q.tty_confirm?
        $stdout.rewind
        $stdout.read.must_match %r{
          CREATE:     .+   #{files[1]}   .+   this-is-a-new-file    .+
          MODIFY:     .+   #{files[4]}   .+
          OVERWRITE:  .+   #{files[3]}   .+
          DELETE:     .+   #{files[5]}   .+   \e\[31mWARNING\e\[0m\sdeletion
        }mx
      }
    end
  end

  describe :summary_table do
    it 'must return an Array of Hashes with :title and :files keys' do
      @q.summary_table.must_be_kind_of Array
      @q.summary_table.size.must_equal 4
      @q.summary_table.each do |h|
        h.must_be_kind_of Hash
        h.keys.sort_by { |k| k.to_s }.must_equal [:files, :title]
        h[:title].must_be_kind_of Array
        h[:title][0].must_match /\A\w+:\z/
        h[:title][1..-1].all? { |e| e.is_a? Symbol }.must_equal true # Enumerable#drop not in 1.8.6
        h[:files].must_be_kind_of Array
      end
    end

    it 'must contain all files and annotations in the queue, in a format suitable for Haus::Logger#fmt' do
      files  = [:file, :link].map { |t| $user.hausfile t }
      logger = Haus::Logger.new

      @q.add_link *files[0]
      @q.annotate files[0].last, 'This is a regular file'
      create = @q.summary_table.first
      logger.fmt(create[:title]).must_match /CREATE:/
      create[:files].must_be_kind_of Array
      create[:files].size.must_equal 1
      create[:files].first.size.must_equal 2
      create[:files].each do |f, note|
        logger.fmt(*f).must_match Regexp.new(files[0][1])
        logger.fmt(*note).must_equal 'This is a regular file'
      end

      FileUtils.touch files[1].last
      @q.add_deletion files[1].last
      @q.annotate files[1].last, 'DELETE ME'
      delete = @q.summary_table.last
      logger.fmt(delete[:title]).must_match /DELETE:/
      delete[:files].must_be_kind_of Array
      delete[:files].size.must_equal 1
      delete[:files].first.size.must_equal 2
      delete[:files].each do |f, note|
        logger.fmt(*f).must_match Regexp.new(files[1][1])
        logger.fmt(*note).must_equal 'DELETE ME'
      end

      # TODO: Modifications and Overwrites
    end
  end

  describe :private do
    describe :log do
      before do
        @buf = StringIO.new
        @q.options = { :logger => Haus::Logger.new(@buf) }
      end

      it "must be a shortcut to the logger's :log method" do
        @q.send :log, 'Open season on Kirkland Bourbon'
        @buf.rewind
        @buf.read.must_equal "Open season on Kirkland Bourbon\n"
      end

      it 'must not write to the io object when options.quiet is set' do
        opts = @q.options.dup
        opts.quiet = true
        @q.options = opts
        @q.send :log, 'SHHH'
        @buf.rewind
        @buf.read.must_equal ''
      end
    end

    describe :fmt do
      # TODO
    end

    describe :relpath do
      it 'must return a relative path to a source' do
        Haus::Utils.relpath('/foo/bar/ride', '/foo/baz/quux').must_equal '../bar/ride'
      end

      it 'must follow the `physical` directory structure, without following symlinks' do
        # /home/test/.haus/one/two/three
        # /home/test/.haus/bridge
        # /home/test/.haus/etc
        three  = File.join $user.haus, *%w[one two three]
        bridge = File.join $user.haus, 'bridge'
        FileUtils.mkdir_p three
        FileUtils.ln_s three, bridge

        src = $user.hausfile.first
        dst = File.join bridge, 'dst'
        Haus::Utils.relpath(src, dst).must_equal "../../../etc/#{File.basename src}"
      end
    end

    describe :linked? do
      it 'must compare src to the link source' do
        src, dst = $user.hausfile
        FileUtils.ln_s '/etc/passwd', dst
        @q.send(:linked?, src, dst).must_equal false
        FileUtils.rm_f dst
        FileUtils.ln_s src, dst
        @q.send(:linked?, src, dst).must_equal true
      end

      it 'must return false if the link source style differs from options.relative' do
        src, dst = $user.hausfile
        FileUtils.ln_s src, dst
        @q.options = { :relative => true }
        @q.send(:linked?, src, dst).must_equal false
        FileUtils.rm_f dst
        FileUtils.ln_s Haus::Utils.relpath(src, dst), dst
        @q.send(:linked?, src, dst).must_equal true
      end
    end

    describe :extant? do
      before do
        @user = Haus::TestUser[:queue_extant?]
      end

      it 'must return true when regular files and directories exist' do
        [:file, :link, :dir].each do |s|
          @q.send(:extant?, @user.hausfile(s).first).must_equal true
        end

        FileUtils.mkdir_p File.join(@user.haus, '.tmp/foo')
        @q.send(:extant?, File.join(@user.haus, '.tmp/foo/bar')).must_equal false
      end

      it 'must return true when passed broken symlinks' do
        src = @user.hausfile.first
        FileUtils.ln_sf src, "#{@user.haus}/lies"
        FileUtils.rm_f src
        File.exist?("#{@user.haus}/lies").must_equal false
        @q.send(:extant?, "#{@user.haus}/lies").must_equal true
      end
    end

    describe :duplicates? do
      # TODO
    end

    describe :blocking_path do
      before do
        @user = Haus::TestUser[:queue_blocking_path]
      end

      it 'must return nil when path nodes are non-extant' do
        @q.send(:blocking_path, '/everlasting/gobstopper').must_equal nil
        path = @user.hausfile(:dir).first
        @q.send(:blocking_path, File.join(path, 'foo/bar')).must_equal nil
      end

      it 'must return the extant tree nodes which are not directories or links to one' do
        dir   = @user.hausfile(:dir).first
        file  = @user.hausfile.first
        ldir  = File.join $user.etc, 'dir'
        lfile = File.join $user.etc, 'file'

        FileUtils.ln_sf dir, ldir
        FileUtils.ln_sf file, lfile

        @q.send(:blocking_path, File.join(dir,   'bar/baz')).must_equal nil
        @q.send(:blocking_path, File.join(file,  'bar/baz')).must_equal file
        @q.send(:blocking_path, File.join(ldir,  'bar/baz')).must_equal nil
        @q.send(:blocking_path, File.join(lfile, 'bar/baz')).must_equal lfile
      end
    end

    describe :raise_if_blocking_path do
      it 'must raise an error if there is a blocking path' do
        assert_raises RuntimeError do
          @q.send :raise_if_blocking_path, File.join($user.hausfile.first, 'foo')
        end
      end
    end

    describe :create_path_to do
      it 'must create all parent directories' do
        path = File.join $user.haus, 'create/path/to'
        extant?(path).must_equal false
        @q.send :create_path_to, path, {}
        extant?(path).must_equal false
        File.directory?(File.dirname path).must_equal true
      end

      it 'must change ownership of all created directories as that of its parent' do
        # TODO: This is how we'd test this
        # path = File.join $user.dir, '.haus-owner/mustbe/test'
        # $user.hausfiles.push "#{$user.dir}/.haus-owner"
        # extant?(path).must_equal false
        # @q.send :create_path_to, path, {}
        # File.stat("#{$user.dir}/.haus-owner").uid.must_equal $user.uid
        # File.stat("#{$user.dir}/.haus-owner").gid.must_equal $user.gid
      end
    end

    describe :adopt do
      # HACK: This is hard to test properly without admin privileges;
      #       following just tests verbose output of command
      it "must change a file's owner and group to match that of its parent" do
        f    = $user.hausfile.first
        stat = File.stat File.dirname(f)
        user = Etc.getpwuid(stat.uid).name
        grp  = Etc.getgrgid(stat.gid).name
        err  = capture_io { @q.send :adopt, f, :verbose => true }[1]
        # NOTE: Some versions of FileUtils#chown_R only accept user/group
        #       names and not uid/gids; this documents that behavior
        err.must_match /\Achown.* #{user}:#{grp} #{f}\Z/
      end

      it 'must break when parent directory does not exist' do
        lambda { @q.send :adopt, '/beagle/with/unsmelly/butt', {} }.must_raise Errno::ENOENT
      end
    end

    describe :execute_deletions do
      # TODO
    end

    describe :execute_links do
      # TODO
    end

    describe :execute_copies do
      # TODO
    end

    describe :execute_modifications do
      # TODO
    end

    describe :tty_getchar do
      # TODO
    end
  end
end
