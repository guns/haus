# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'fileutils'
require 'ostruct'
require 'expect'
require 'stringio'
require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if [].respond_to? :cycle
require 'minitest/autorun'
require 'haus/queue'
require 'haus/logger'
require 'haus/test/helper/minitest'
require 'haus/test/helper/test_user'

$user ||= Haus::TestUser[$$]

class Haus::QueueSpec < MiniTest::Spec
  before do
    @q = Haus::Queue.new :quiet => true
  end

  describe :initialize do
    it 'must optionally accept an options object' do
      @q.method(:initialize).arity.must_equal -1
      Haus::Queue.new.options.must_equal OpenStruct.new
      q = Haus::Queue.new OpenStruct.new(:force => true)
      q.options.must_equal OpenStruct.new(:force => true)
      q.options.frozen?.must_equal true
    end

    it 'must initialize the attr_readers, which should be frozen' do
      %w[links copies modifications deletions].each do |m|
        @q.send(m).must_equal []
        @q.send(m).frozen?.must_equal true
      end
      @q.archive_path.must_match %r{\A/tmp/haus-\d+-\d+-\d+-[a-z]+\.tar\.gz\z}
      @q.archive_path.frozen?.must_equal true
    end
  end

  describe :options= do
    before do
      @assertion = lambda do |q|
        q.options.force.must_equal true
        q.options.frozen?.must_equal true
        lambda { q.options.force = false }.must_raise TypeError
      end
    end

    it 'must dup and freeze the passed OpenStruct object' do
      opts = OpenStruct.new :force => true, :noop => true
      @q.options = opts
      @q.options.must_equal opts
      opts.force = false
      @assertion.call @q.dup
    end

    it 'must accept a Hash as an argument' do
      opts = { :force => true, :noop => true }
      @q.options = opts
      @q.options.must_equal OpenStruct.new(opts)
      opts.must_equal :force => true, :noop => true
      opts[:force] = false
      @assertion.call @q.dup
    end
  end

  describe :add_link do
    it 'must noop and return nil when src does not exist' do
      @q.add_link('/magic/pony/with/sparkles', "#{$user.dir}/sparkles").must_be_nil
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
        relpath = lambda { |src, dst| Pathname.new(src).relative_path_from(Pathname.new File.dirname(dst)).to_s }

        @assertion.call lambda { |src, dst|
          FileUtils.ln_sf relpath.call(src, dst), dst
        }, nil

        @assertion.call lambda { |src, dst|
          FileUtils.ln_sf src, dst
        }, { :relative => true }
      end

      it 'must remove the destination before linking' do
        @assertion.call lambda { |src, dst|
          FileUtils.mkdir_p File.join(dst, 'sparkle')
          FileUtils.touch File.join(dst, 'sparkle', 'pony')
        }, nil
      end
    end
  end

  describe :add_copy do
    it 'must noop and return nil when src does not exist' do
      @q.add_copy('/magic/pony/with/sparkles', "#{$user.dir}/sparkles").must_be_nil
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
          File.open("#{src}/pony", 'w') { |f| f.write 'PONY!' }
          File.open("#{dst}/pony", 'w') { |f| f.write 'HORSE!' }
        }
      end

      it 'must remove destination before copying' do
        @assertion.call lambda { |src, dst| File.open(dst, 'w') { |f| f.write dst } }
        @assertion.call lambda { |src, dst|
          FileUtils.mkdir_p File.join(dst, 'sparkle')
          FileUtils.touch File.join(dst, 'sparkle', 'pony')
        }
      end
    end
  end

  describe :add_deletion do
    it 'must noop and return nil when dst does not exist' do
      @q.add_deletion('/magical/pony/with/sparkle/action').must_be_nil
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

    it 'must raise an error if argument is a directory' do
      lambda { @q.add_modification($user.dir) {} }.must_raise ArgumentError
    end
  end

  describe :targets do
    # Fill up a queue
    before do
      @files   = (0..7).map { $user.hausfile }
      @targets = @files.map { |s,d| d }

      # Pre-create targets for some
      [1,3,4,5,7].each { |n| File.open(@targets[n], 'w') { |f| f.puts 'EXTANT' } }

      8.times do |n|
        case n
        when 0..1 then @q.add_link *@files[n]
        when 2..3 then @q.add_copy *@files[n]
        when 4..5 then @q.add_deletion @targets[n]
        when 6..7 then @q.add_modification(@targets[n]) { |f| f }
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
      @q.targets(:create).sort.must_equal @targets.values_at(0,2,6).sort
    end

    it 'must return all files to be modified on :modify' do
      @q.targets(:modify).must_equal @targets.values_at(7)
    end

    it 'must return all files that will be overwritten on :overwrite' do
      @q.targets(:overwrite).must_equal @targets.values_at(1,3)
    end

    it 'must return all files that should be archived on :archive' do
      @q.targets(:archive).sort.must_equal @targets.select { |f| File.exists? f }.sort
    end

    it 'must be a complete list of targets with no overlapping entries' do
      [:delete, :create, :modify, :overwrite].inject [] do |a,m|
        a + @q.targets(m)
      end.sort.must_equal @targets.sort
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
      @files   = (0..9).map { $user.hausfile }
      @sources = @files.map { |s,d| s }
      @targets = @files.map { |s,d| d }

      # Pre-create targets for some
      [3,4,5].each { |n| File.open(@targets[n], 'w') { |f| f.write 'EXTANT' } }

      10.times do |n|
        case n
        when 0..1, 8..9 then @q.add_link *@files[n]
        when 2..3       then @q.add_copy *@files[n]
        when 4..5       then @q.add_deletion @targets[n]
        when 6..7       then
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
      File.exists?(@q.archive_path).must_equal true
    end

    it 'must not create an archive if options.noop is specified' do
      @q.options = { :noop => true, :quiet => true }
      @q.execute!
      File.exists?(@q.archive_path).must_equal false
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
            print 'foo' if File.exists? @targets[3]
            print 'bar'
            kill sig, $$
            sleep 1
            # Should not print due to signal
            print 'baz'
          end
          @q.execute!
        end.first.must_equal 'bar'

        # But the rollback should have restored previously extant files
        @targets.select { |f| File.exists? f }.must_equal @targets.values_at(3,4,5)
      end
    end

    it 'must rollback changes on StandardError' do
      target = $user.hausfile.last

      capture_fork_io do
        @q.add_modification target do |f|
          FileUtils.rm_rf @targets, :secure => true
          print 'foo' if File.exists? @targets[3]
          print 'bar'
          raise StandardError
          print 'baz'
        end
        @q.execute!
      end.first.must_equal 'bar'

      @targets.select { |f| File.exists? f }.must_equal @targets.values_at(3,4,5)
    end

    it 'must delete files' do
      [4,5].each { |n| File.exists?(@targets[n]).must_equal true }
      @q.execute!
      [4,5].each { |n| File.exists?(@targets[n]).must_equal false }
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
        relpath = Pathname.new(@sources[n]).relative_path_from(Pathname.new File.dirname(@targets[n])).to_s
        File.readlink(@targets[n]).must_equal relpath
        File.expand_path(File.readlink(@targets[n]), File.dirname(@targets[n])).must_equal @sources[n]
      end
    end

    it 'must copy files' do
      File.exists?(@targets[2]).must_equal false
      File.exists?(@targets[3]).must_equal true
      FileUtils.cmp(@sources[3], @targets[3]).must_equal false
      @q.execute!
      [2,3].each { |n| FileUtils.cmp(@sources[n], @targets[n]).must_equal true }
    end

    it 'must copy links, not their sources' do
      src, dst = $user.hausfile :link
      q = Haus::Queue.new :quiet => true, :force => true
      File.lstat(src).ftype.must_equal 'link'
      q.add_copy src, dst
      q.copies.must_equal [[src, dst]]
      q.execute!
      File.lstat(dst).ftype.must_equal 'link'
    end

    it 'must modify files' do
      [6,7].each { |n| File.open(@targets[n], 'w') { |f| f.write 'CREATED' } }
      @q.execute!
      [6,7].each { |n| File.read(@targets[n]).must_equal 'MODIFIED' }
    end

    it 'must touch files before calling modification proc' do
      target = $user.hausfile.last
      File.exists?(target).must_equal false
      @q.add_modification $user.hausfile.last do |f|
        File.exists?(f).must_equal true
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
        targets.each { |f| File.exists?(f).must_equal true }
      ensure
        FileUtils.rm_rf targets.map { |f| File.dirname f }
      end
    end

    it 'must create files with owner-only privileges, but should not change the process umask' do
      @q.execute!
      @targets.values_at(0..3, 6..9).each do |f|
        File.lstat(f).mode.to_s(8)[/.{2}\z/].must_equal '00'
      end
      File.umask.to_s(8)[/.{2}\z/].wont_equal '77'
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
      @q.add_link '/etc/passwd', '/magical/pony/with/sparkles'
      @q.add_copy '/etc/passwd', '/magical/pony/with/flying/action'
      @q.add_modification('/magical/pony/in/the/sky') { |f| f }
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
      File.exists?(@q.archive_path).must_equal true
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
      @targets.map { |f| File.exists? f }.uniq.must_equal [false]
      @q.restore
      @targets.map { |f| File.exists? f }.uniq.must_equal [true]
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

      with_confirmation.call lambda { @q.options = {};                 @q.tty_confirm?.must_equal true }
      with_confirmation.call lambda { @q.options = { :quiet => true }; @q.tty_confirm?.must_equal false }
    end

    it 'must return false when $stdin is not a tty' do
      with_filetty do
        $stdout.expect 'continue? [Y/n] ', 1 do
          $stdin.write "Y\n"
          $stdin.rewind
        end
        @q.options = {}
        @q.tty_confirm?.must_equal true
        $stdin.instance_eval do
          def tty?; false end
          def isatty?; false end
        end
        @q.tty_confirm?.must_equal false
      end
    end

    it 'must request user input from $stdin when from a terminal' do
      @q.options = {}
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
  end

  describe :private do
    before do
      @buf = StringIO.new
      @q.options = { :logger => Haus::Logger.new(@buf) }
    end

    describe :log do
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

    describe :relpath do
      it 'must return a relative path to a source' do
        @q.send(:relpath, '/magic/pony/ride', '/magic/sparkle/action').must_equal '../pony/ride'
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
        FileUtils.ln_s Pathname.new(src).relative_path_from(Pathname.new File.dirname(dst)).to_s, dst
        @q.send(:linked?, src, dst).must_equal true
      end
    end

    describe :duplicates? do
      # TODO
    end
  end
end
