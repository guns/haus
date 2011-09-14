# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'stringio'
require 'enumerator' # 1.8.6 compat
require 'haus/task'
require 'haus/test/helper/minitest'
require 'haus/test/helper/noop_tasks'
require 'haus/test/helper/test_user'

$user ||= Haus::TestUser[$$]

class Haus::TaskSpec < MiniTest::Spec
  describe :self do
    describe :list do
      # http://stackoverflow.com/questions/3434884/accessing-ruby-class-variables-with-class-eval-and-instance-eval
      it 'must return the metaclass @@list variable' do
        Haus::Task.list.must_be_kind_of Hash
      end
    end

    describe :command do
      it "must return the current subclass's command name" do
        Haus::Noop.command.must_equal 'noop'
        Haus::Noop2.command.must_equal 'noop2'
      end
    end

    describe :inherited do
      it 'must create a Task::list entry for the new subclass' do
        Haus::Task.list['noop2'].must_be_kind_of Hash
        Haus::Task.list['noop2'][:class].must_equal Haus::Noop2
        Haus::Task.list['noop2'][:desc].must_equal ''
        Haus::Task.list['noop2'][:help].must_equal ''
      end
    end

    describe :desc do
      it 'must set the one line description for the subclass' do
        msg = 'This class does nothing.'
        Haus::Noop.desc msg
        Haus::Task.list['noop'][:desc].must_equal msg
      end
    end

    describe :help do
      it 'must set the help output header' do
        msg = 'This class does nothing; its purpose is to ease automated testing.'
        Haus::Noop.help msg
        Haus::Task.list['noop'][:help].must_equal msg
      end
    end

    describe :summary do
      it 'must return a summary of all subclasses of Haus::Task' do
        buf = Haus::Task.summary
        Haus::Task.list.keys.each do |cmd|
          buf.must_match Regexp.new('^\s+' + cmd)
        end
      end
    end
  end

  describe :initialize do
    it 'must accept an optional arguments Array' do
      Haus::Noop.method(:initialize).arity.must_equal -1
      Haus::Noop.new(%w[-f noprocrast]).instance_variable_get(:@args).must_equal %w[-f noprocrast]
    end
  end

  describe :queue do
    it 'must always return a Queue instance' do
      h = Haus::Noop.new
      h.queue.must_be_kind_of Haus::Queue
    end
  end

  describe :meta do
    it 'must access the Task::list entry for the current subclass' do
      h = Haus::Noop.new
      h.meta.must_be_kind_of Hash
      h.meta[:class].must_equal Haus::Noop
      h.meta[:desc].must_equal Haus::Task.list['noop'][:desc]
      h.meta[:help].must_equal Haus::Task.list['noop'][:help]
    end
  end

  describe :users do
    it 'must return Haus::Task#options.users' do
      h = Haus::Noop.new
      h.users.must_equal h.options.users
      h.options.users = [0]
      h.users.must_equal [Haus::User.new(0)]
      h.users.must_equal h.options.users
    end
  end

  describe :log do
    it "must be a shortcut to the logger's :log method" do
      h, buf = Haus::Noop.new, StringIO.new
      h.options.logger.io = buf
      h.log 'MooMooMoo'
      buf.rewind
      buf.read.must_equal "MooMooMoo\n"
    end

    it 'must not write to the io object when options.quiet is set' do
      h, buf = Haus::Noop.new, StringIO.new
      h.options.logger.io = buf
      h.options.quiet = true
      h.log 'QUIET!'
      buf.rewind
      buf.read.must_equal ''
    end
  end

  describe :etc do
    it 'must return HAUS_PATH/etc' do
      h = Haus::Noop.new
      h.etc.must_equal File.join(h.options.path, 'etc')
      h.options.path = '/tmp/haus'
      h.etc.must_equal '/tmp/haus/etc'
    end
  end

  describe :hausfiles do
    before do
      @task = Haus::Noop.new
    end

    it 'must accept a single user name, uid, or Haus::User object' do
      @task.method(:hausfiles).arity.must_equal 1
      assert_raises StandardError do
        @task.hausfiles $user.uid
        @task.hausfiles $user.name
        @task.hausfiles Haus::User.new($user.uid)
        raise StandardError
      end
    end

    it 'must return a table of [[src, user-dst], ...] given a specific user' do
      user = Haus::TestUser[:task_hausfiles]
      @task.options.path = user.haus
      [:file, :link, :dir, :hier].each { |t| user.hausfile t }

      # Ruby 1.8.6 can't do flat_ary.each_slice(2).to_a
      ary = []
      user.hausfiles.each_slice(2) { |a| ary.push a }
      @task.hausfiles(user.uid).sort.must_equal ary.sort
    end

    it 'must accept a block to iterate over the [src, user-dst] pairs' do
      user = Haus::TestUser[:task_hausfiles_yield]
      @task.options.path = user.haus
      [:file, :link, :dir, :hier].each { |t| user.hausfile t }

      ary = []
      @task.hausfiles(user.uid) { |s, d| ary.push [s, d] }
      @task.hausfiles(user.uid).sort.must_equal ary.sort
    end
  end

  describe :dotfiles do
    it 'must return all non-hierdir files in HAUS_PATH/etc/*' do
      h, user, files = Haus::Noop.new, Haus::TestUser[:task_etcfiles], []
      h.options.path = user.haus

      files << user.hausfile(:file).first
      files << user.hausfile(:dir).first
      files << user.hausfile(:link).first

      # Non etcfiles
      File.join(user.etc, '.dotfile')
      FileUtils.touch File.join(user.etc, '.dotfile')
      user.hausfile :hier

      h.dotfiles.sort.must_equal files.sort
    end
  end

  describe :hierfiles do
    it 'must return all file nodes within hierdirs within HAUS_PATH/etc' do
      h, user, files = Haus::Noop.new, Haus::TestUser[:task_hierfiles], []
      h.options.path = user.haus

      # Not hierfiles!
      user.hausfile :file
      user.hausfile :dir
      user.hausfile :link

      hierdir = File.dirname user.hausfile(:hier).first
      FileUtils.rm_rf Dir["#{hierdir}/*"]

      %w[foorc %foo.d/myfoorc %foo.d/config node/barrc].each do |rel|
        path = File.join hierdir, rel
        FileUtils.mkdir_p File.dirname(path)
        FileUtils.touch path
        files << (rel =~ /\Anode/ ? File.dirname(path) : path)
      end

      # Not a hierfile
      FileUtils.touch File.join(hierdir, '.foo')

      h.hierfiles.sort.must_equal files.sort
    end
  end

  describe :hierdir? do
    before do
      @task = Haus::Noop.new
    end

    it 'must return false when argument is not a directory' do
      src = File.dirname $user.hausfile(:hier).first
      @task.hierdir?(src).must_equal true
      FileUtils.rm_rf src
      FileUtils.touch src
      @task.hierdir?(src).must_equal false
    end

    it 'must return false when argument does not begin with a `%` character' do
      begin
        testdir  = $user.hausfile(:dir).first
        testhier = File.join File.dirname(testdir), '%' + File.basename(testdir)
        FileUtils.mkdir_p [testdir, testhier]
        @task.hierdir?(testdir).must_equal false
        @task.hierdir?(testhier).must_equal true
      ensure
        FileUtils.rm_rf [testdir, testhier]
      end
    end
  end

  describe :options do
    describe :users= do
      it 'must set the users option' do
        users     = [0, Etc.getlogin]
        haususers = users.map { |u| Haus::User.new u }

        opt = Haus::Noop.new.options
        opt.users = users
        opt.instance_variable_get(:@ostruct).users.must_equal haususers
        opt.users.must_equal haususers
      end
    end

    it 'must be an instance of Haus::Options' do
      Haus::Noop.new.options.must_be_kind_of Haus::Options
    end

    it 'must have its own help message' do
      Haus::Noop.new.options.to_s.must_match /^Usage:.+ noop/
    end

    it 'must provide the default users list' do
      h = Haus::Noop.new
      ostruct = h.options.instance_variable_get :@ostruct
      ostruct.users.must_be_kind_of Array
      ostruct.users.first.must_be_kind_of Haus::User
      ostruct.users.must_equal [Haus::User.new]
      h.options.users.must_equal [Haus::User.new]
    end

    it 'must provide the default command line options for all Task subclasses' do
      runoptions = lambda { |args| h = Haus::Noop.new args; h.run; h.options }
      users = [0, $user.name, Etc.getlogin]

      runoptions.call(%w[--path /opt/testhaus]).path.must_equal '/opt/testhaus'
      runoptions.call(%W[--users #{users.join ','}]).users.must_equal users.map { |u| Haus::User.new u }
      runoptions.call(%w[--force]).force.must_equal true
      runoptions.call(%w[--noop]).noop.must_equal true
      runoptions.call(%w[--quiet]).quiet.must_equal true
      capture_fork_io { Haus::Noop.new(%w[--help]).run }.first.must_equal Haus::Noop.new.options.to_s
    end
  end

  describe :run do
    it 'must return the remaining ARGV after options parsing' do
      h = Haus::Noop.new %w[--force --quiet magic pony]
      h.run.must_equal %w[magic pony]
    end
  end
end
