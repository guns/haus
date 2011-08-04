# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'fileutils'
require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and [].respond_to? :cycle
require 'minitest/autorun'
require 'haus/link'
require 'haus/test/helper/test_user'

class Haus::LinkSpec < MiniTest::Spec
  before do
    @link = Haus::Link.new
    @link.options.force = true
    @link.options.quiet = true
  end

  after do
    FileUtils.rm_f @link.queue.archive_path
  end

  describe :options do
    it 'should provide a --relative option' do
      h = Haus::Link.new %w[--relative]
      h.run
      h.options.relative.must_equal true
    end
  end

  describe :enqueue do
    it 'should add link jobs to the queue' do
      user = Haus::TestUser[:link_enqueue]
      jobs = [:file, :dir, :link].inject({}) { |h,m| h.merge Hash[*user.hausfile(m)] } # Ruby 1.8.6

      @link.options.path = user.haus
      @link.options.users = [user.name]
      @link.enqueue
      @link.queue.links.map { |s,d| s }.sort.must_equal jobs.keys.sort
      @link.queue.targets.sort.must_equal jobs.values.sort
    end
  end

  describe :run do
    it 'should pass options to queue before enqueueing files' do
      @link.instance_eval do
        def enqueue *args
          queue.options.cow.must_equal 'MOOCOW'
          super
        end
      end

      @link.options.cow = 'MOOCOW'
      @link.run
      @link.queue.options.cow.must_equal 'MOOCOW'
    end

    it 'should pass options to queue before execution' do
      @link.instance_eval do
        def execute *args
          queue.options.cow.must_equal 'MOOCOW'
          super
        end
      end

      @link.options.cow = 'MOOCOW'
      @link.run
      @link.queue.options.cow.must_equal 'MOOCOW'
    end

    it 'should execute the queue' do
      @link.queue.executed?.must_equal nil
      @link.run
      @link.queue.executed?.must_equal true
    end

    it 'should link all sources as dotfiles' do
      user = Haus::TestUser[:link_run]
      jobs = [:file, :dir, :link].inject({}) { |h,m| h.merge Hash[*user.hausfile(m)] } # Ruby 1.8.6
      jobs.values.each { |f| File.exists?(f).must_equal false }

      @link.options.path = user.haus
      @link.options.users = [user.name]
      @link.run

      jobs.values.each do |f|
        # Ruby 1.9 has Hash#key
        File.readlink(f).must_equal jobs.find { |s,d| d == f }.first
      end
    end

    it 'should return true or nil' do
      @link.options.quiet = true
      @link.options.force = true
      @link.run.must_equal true
      @link.options.force = false
      @link.run.must_equal nil
    end
  end
end
