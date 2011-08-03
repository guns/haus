# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'fileutils'
require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and [].respond_to? :cycle
require 'minitest/autorun'
require 'haus/copy'
require 'haus/test/helper/test_user'

describe Haus::Copy do
  before do
    @copy = Haus::Copy.new
    @copy.options.force = true
    @copy.options.quiet = true
  end

  after do
    FileUtils.rm_f @copy.queue.archive_path
  end

  describe :enqueue do
    it 'should add copy jobs to the queue' do
      user = Haus::TestUser[:copy_enqueue]
      jobs = [:file, :dir].inject({}) { |h,m| h.merge Hash[*user.hausfile(m)] } # Ruby 1.8.6

      @copy.options.path = user.haus
      @copy.options.users = [user.name]
      @copy.enqueue
      @copy.queue.copies.map { |s,d| s }.sort.must_equal jobs.keys.sort
      @copy.queue.targets.sort.must_equal jobs.values.sort
    end
  end

  describe :run do
    it 'should pass options to queue before enqueueing files' do
      @copy.instance_eval do
        def enqueue *args
          queue.options.cow.must_equal 'MOOCOW'
          super
        end
      end

      @copy.options.cow = 'MOOCOW'
      @copy.run
      @copy.queue.options.cow.must_equal 'MOOCOW'
    end

    it 'should pass options to queue before execution' do
      @copy.instance_eval do
        def execute *args
          queue.options.cow.must_equal 'MOOCOW'
          super
        end
      end

      @copy.options.cow = 'MOOCOW'
      @copy.run
      @copy.queue.options.cow.must_equal 'MOOCOW'
    end

    it 'should execute the queue' do
      @copy.queue.executed?.must_equal nil
      @copy.run
      @copy.queue.executed?.must_equal true
    end

    it 'should copy all sources as dotfiles' do
      user = Haus::TestUser[:copy_run]
      jobs = [:file, :dir].map { |m| user.hausfile m }
      jobs.each { |s,d| File.exists?(d).must_equal false }

      @copy.options.path = user.haus
      @copy.options.users = [user.name]
      @copy.run

      s0, d0 = jobs[0]
      FileUtils.cmp(s0, d0).must_equal true
      s1, d1 = jobs[1]
      Dir[s1 + '/*'].zip(Dir[d1 + '/*']).each do |s,d|
        FileUtils.cmp(s,d).must_equal true
      end
    end
  end
end
