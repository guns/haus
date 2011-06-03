# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../lib', __FILE__)

require 'fileutils'
require 'ostruct'
require 'expect'
require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and [].respond_to? :cycle
require 'minitest/autorun'
require 'haus/queue'
require 'haus/test/helper/minitest'
require 'haus/test/helper/test_user'

$user = Haus::TestUser[$$]

describe Haus::Queue do
  before do
    @q = Haus::Queue.new
  end

  it 'should have included FileUtils' do
    Haus::Queue.included_modules.must_include FileUtils
  end

  describe :initialize do
    it 'should optionally accept an options object' do
      @q.method(:initialize).arity.must_equal -1
      @q.options.must_equal OpenStruct.new
      q = Haus::Queue.new(OpenStruct.new :force => true)
      q.options.must_equal OpenStruct.new(:force => true)
      q.options.frozen?.must_equal true
    end

    it 'should initialize the attr_readers, which should be frozen' do
      %w[links copies modifications deletions].each do |m|
        @q.send(m).must_equal []
        @q.send(m).frozen?.must_equal true
      end
      @q.archive_path.must_match %r{\A/tmp/haus-\d+-[a-z]+\.tar\.gz\z}
      @q.archive_path.frozen?.must_equal true
    end
  end

  describe :options= do
    it 'should dup and freeze the passed object' do
      opts = OpenStruct.new :force => true, :noop => true
      @q.options = opts
      @q.options.must_equal opts
      opts.force = false
      @q.options.force.must_equal true
      @q.options.frozen?.must_equal true
      assert_raises TypeError do
        @q.options.force = false
      end
    end
  end

  describe :add_link do
    it 'should noop and return nil when src does not exist' do
      @q.add_link('/magic/pony/with/sparkles', "#{$user.dir}/sparkles").must_be_nil
      @q.links.empty?.must_equal true
    end

    it 'should noop and return nil when dst points to src' do
      src, dst = $user.hausfile
      FileUtils.ln_s src, dst
      @q.add_link(src, dst).must_be_nil
      @q.links.empty?.must_equal true
    end

    it 'should push and refreeze @links when src does exist and dst does not point to src' do
      args = $user.hausfile
      res = @q.add_link *args
      res.must_equal [args]
      res.frozen?.must_equal true
      @q.links.must_equal [args]
      @q.links.frozen?.must_equal true
    end

    it 'should raise an error when a job for dst already exists' do
      args = $user.hausfile
      @q.add_link *args
      assert_raises Haus::Queue::MultipleJobError do
        @q.add_link *args
      end
    end
  end

  describe :add_copy do
    it 'should noop and return nil when src does not exist' do
      @q.add_copy('/magic/pony/with/sparkles', "#{$user.dir}/sparkles").must_be_nil
      @q.copies.empty?.must_equal true
    end

    it 'should noop and return nil when src and dst equal' do
      src, dst = $user.hausfile
      FileUtils.cp src, dst
      @q.add_copy(src, dst).must_be_nil
      @q.copies.empty?.must_equal true
    end

    it 'should push and refreeze @copies when src exists and dst does not equal src' do
      args = $user.hausfile
      res = @q.add_copy *args
      res.must_equal [args]
      res.frozen?.must_equal true
      @q.copies.must_equal [args]
      @q.copies.frozen?.must_equal true
    end

    it 'should raise an error when a job for dst already exists' do
      args = $user.hausfile
      @q.add_copy *args
      assert_raises Haus::Queue::MultipleJobError do
        @q.add_copy *args
      end
    end
  end

  describe :add_deletion do
    it 'should noop and return nil when dst does not exist' do
      @q.add_deletion('/magical/pony/with/sparkle/action').must_be_nil
      @q.deletions.empty?.must_equal true
    end

    it 'should push and refreeze @deletions when dst exists' do
      src = $user.hausfile.first
      res = @q.add_deletion src
      res.must_equal [src]
      res.frozen?.must_equal true
      @q.deletions.must_equal [src]
      @q.deletions.frozen?.must_equal true
    end

    it 'should raise an error when a job for dst already exists' do
      src = $user.hausfile.first
      @q.add_deletion src
      assert_raises Haus::Queue::MultipleJobError do
        @q.add_deletion src
      end
    end
  end

  describe :add_modification do
    it 'should noop and return nil when no block is given' do
      @q.add_modification("#{$user.dir}/.ponies").must_be_nil
      @q.modifications.empty?.must_equal true
    end

    it 'should push and return @modifications when a file and block are given' do
      res = @q.add_modification("#{$user.dir}/.ponies") { |f| touch f }
      res.size.must_equal 1
      res.frozen?.must_equal true
      @q.modifications.first[0].respond_to?(:call).must_equal true # TODO: must_respond_to, Y U NO WORK?
      @q.modifications.first[1].must_equal "#{$user.dir}/.ponies"
      @q.modifications.frozen?.must_equal true
    end

    it 'should raise an error when a job for dst already exists' do
      src = $user.hausfile.first
      @q.add_modification(src) { |f| touch f }
      assert_raises Haus::Queue::MultipleJobError do
        @q.add_modification(src) { |f| touch f }
      end
    end
  end

  # describe :targets do
  #   # Fill up a queue
  #   before do
  #     @files = (0..7).map { |n| "#{$user.dir}/.#{File.basename $user.hausfiles[n]}" }

  #     [1,3,4,5,7].each { |n| File.open(@files[n], 'w') { |f| f.puts 'EXTANT' } }

  #     8.times do |n|
  #       case n
  #       when 0..1 then @q.add_link $user.hausfiles[n], @files[n]
  #       when 2..3 then @q.add_copy $user.hausfiles[n], @files[n]
  #       when 4..5 then @q.add_deletion @files[n]
  #       when 6..7 then @q.add_modification(@files[n]) { |io| io.puts 'MODIFY' }
  #       end
  #     end
  #   end

  #   after do
  #     rm_f @files
  #   end

  #   it 'should return all targets by default' do
  #     @q.targets.sort.must_equal @files.sort
  #     @q.targets(:all).sort.must_equal @files.sort
  #   end

  #   it 'should return all files to be removed on :delete' do
  #     @q.targets(:delete).must_equal @files.values_at(4,5)
  #   end

  #   it 'should return all new files on :create' do
  #     @q.targets(:create).sort.must_equal @files.values_at(0,2,6).sort
  #   end

  #   it 'should return all files to be modified on :modify' do
  #     @q.targets(:modify).must_equal @files.values_at(7)
  #   end

  #   it 'should return all files that will be overwritten on :overwrite' do
  #     @q.targets(:overwrite).must_equal @files.values_at(1,3)
  #   end

  #   it 'should be a complete list of targets with no overlapping entries' do
  #     [:delete, :create, :modify, :overwrite].inject [] do |a,m|
  #       a + @q.targets(m)
  #     end.sort.must_equal @files.sort
  #   end
  # end

  describe :hash do
    it 'should return a hash of the concatenation of all job queues' do
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
    it 'should remove jobs by destination path' do
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
  end

  # describe :execute! do
  #   before do
  #     @files = $user.hausfiles.map { |f| "#{$user.dir}/.#{File.basename f}" }
  #     @files.size.times do |n|
  #       case n
  #       when 8..9   then @q.add_link $user.hausfiles[n], @files[n]
  #       when 10     then @q.add_copy $user.hausfiles[n], @files[n]
  #       when 11     then FileUtils.cp '/etc/passwd', @files[n] and @q.add_copy $user.hausfiles[n], @files[n]
  #       when 12..13 then FileUtils.touch @files[n] and @q.add_deletion @files[n]
  #       when 14..15 then @q.add_modification(@files[n]) { |f| File.open(f, 'a') { |io| io.puts 'MODIFIED' } }
  #       end
  #     end
  #   end

  #   after do
  #     rm_f @q.archive_path
  #     rm_rf @files, :secure => true
  #   end

  #   it 'should return nil if already executed' do
  #     @q.execute!
  #     @q.executed?.must_equal true
  #     @q.execute!.must_equal nil
  #   end

  #   it 'should create an archive before execution' do
  #     @q.execute!
  #     File.exists?(@q.archive_path).must_equal true
  #   end

  #   it 'should rollback changes on signals' do
  #     %w[INT TERM QUIT].each do |sig|
  #       capture_fork_io do
  #         @q.add_modification @files[16] do |f|
  #           rm_rf @files, :secure => true
  #           print 'foo' if File.exists? @files[12]
  #           print 'bar'
  #           kill sig, $$
  #           sleep 1
  #           print 'baz'
  #         end
  #         @q.execute!
  #       end.first.must_equal 'bar'

  #       @files.find { |f| File.exists? f }.must_equal @files[12]
  #     end
  #   end

  #   it 'should rollback changes on StandardError' do
  #     capture_fork_io do
  #       @q.add_modification @files[16] do |f|
  #         rm_rf @files, :secure => true
  #         print 'foo' if File.exists? @files[12]
  #         print 'bar'
  #         raise StandardError
  #       end
  #       @q.execute!
  #     end.first.must_equal 'bar'

  #     File.exists?(@files[12]).must_equal true
  #   end

  #   it 'should delete files' do
  #     [12,13].each { |n| File.exists?(@files[n]).must_equal true }
  #     @q.execute!
  #     [12,13].each { |n| File.exists?(@files[n]).must_equal false }
  #   end

  #   it 'should link files' do
  #     [8,9].each { |n| File.symlink?(@files[n]).must_equal false }
  #     @q.execute!
  #     [8,9].each do |n|
  #       File.symlink?(@files[n]).must_equal true
  #       File.readlink(@files[n]).must_equal $user.hausfiles[n]
  #     end
  #   end

  #   it 'should copy files' do
  #     File.exists?(@files[10]).must_equal false
  #     File.exists?(@files[11]).must_equal true
  #     (File.basename(@files[11]) == File.basename($user.hausfiles[11])).must_equal false
  #     @q.execute!
  #     File.exists?(@files[10]).must_equal true
  #   end
  # end

  describe :executed? do
    it 'should return @executed' do
      @q.executed?.must_equal nil
      @q.instance_variable_set :@executed, true
      @q.executed?.must_equal true
    end
  end

  # describe :archive do
  #   before do
  #     @q.add_link '/etc/passwd', $user.hausfiles[0]
  #     @q.add_copy '/etc/passwd', $user.hausfiles[1]
  #     @q.add_modification($user.hausfiles[2]) { |f| f }
  #     @q.add_deletion $user.hausfiles[3]
  #     @q.add_link '/etc/passwd', '/magical/pony/with/sparkles'
  #     @q.add_copy '/etc/passwd', '/magical/pony/with/flying/action'
  #     @q.add_modification('/magical/pony/in/the/sky') { |f| f }
  #   end

  #   after do
  #     FileUtils.rm_f @q.archive_path
  #   end

  #   it 'should raise an error if tar or gzip are not available' do
  #     begin
  #       path = ENV['PATH'].dup
  #       assert_raises RuntimeError do
  #         ENV['PATH'] = ''
  #         @q.archive
  #       end
  #     ensure
  #       ENV['PATH'] = path
  #     end
  #   end

  #   it 'should create an archive of all extant targets' do
  #     @q.archive
  #     File.exists?(@q.archive_path).must_equal true
  #     list = %x(tar tf #{@q.archive_path} 2>/dev/null).split "\n"
  #     list.sort.must_equal((@q.targets - @q.targets(:create)).map { |f| f.sub /\A\//, '' }.sort)
  #   end

  #   it 'should return the archive path on success' do
  #     @q.archive.must_equal @q.archive_path
  #   end
  # end

  # describe :restore do
  #   before do
  #     @q.instance_variable_set :@deletions, $user.hausfiles[8..23]
  #     @q.options = OpenStruct.new :quiet => true
  #   end

  #   after do
  #     FileUtils.rm_f @q.archive_path
  #   end

  #   it 'should restore the current archive' do
  #     @q.archive
  #     list = %x(tar tf #{@q.archive_path} 2>/dev/null).split("\n").reject do |f|
  #       f =~ %r{haus-\w+/haus-\w+\z}
  #     end.map { |f| f.chomp '/' }
  #     list.sort.must_equal $user.hausfiles[8..23].map { |f| f.sub %r{\A/}, '' }.sort
  #     FileUtils.rm_rf $user.hausfiles[8..23]
  #     $user.hausfiles[8..23].map { |f| File.exists? f }.uniq.must_equal [false]
  #     @q.restore
  #     $user.hausfiles[8..23].map { |f| File.exists? f }.uniq.must_equal [true]
  #   end
  # end

  describe :tty_confirm? do
    before do
      @q.add_link *$user.hausfile
    end

    it 'should return true when force is set' do
      with_no_stdin do
        @q.tty_confirm?.must_equal false
        @q.options = OpenStruct.new :force => true
        @q.tty_confirm?.must_equal true
      end
    end

    it 'should return true when noop is set' do
      with_no_stdin do
        @q.tty_confirm?.must_equal false
        @q.options = OpenStruct.new :noop => true
        @q.tty_confirm?.must_equal true
      end
    end

    it 'should return true when queue is clear' do
      with_no_stdin do
        @q.tty_confirm?.must_equal false
        @q.remove @q.targets.first
        @q.tty_confirm?.must_equal true
      end
    end

    it 'should request user input from $stdin when from a terminal' do
      # TODO: Would be nice to thread this loop
      %W[\n y\n ye\n yes\n YeS\n n\n no\n nO\n].each do |str|
        with_filetty do
          $stdout.expect 'continue? [Y/n] ', 1 do
            $stdin.write str
            $stdin.rewind
          end
          @q.tty_confirm?.must_equal !(str =~ /\An/i)
        end
      end
    end
  end
end
