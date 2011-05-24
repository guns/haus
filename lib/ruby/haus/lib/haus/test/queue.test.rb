# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../lib', __FILE__)

require 'fileutils'
require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and [].respond_to? :cycle
require 'minitest/autorun'
require 'haus/queue'
require 'haus/test/helper'

$user = Haus::TestUser[$$]

describe Haus::Queue do
  before do
    @q = Haus::Queue.new
  end

  it 'should have included FileUtils' do
    Haus::Queue.included_modules.must_include FileUtils
  end

  describe :initialize do
    it 'should initialize the attr_readers, which should be frozen' do
      %w[links copies modifications deletions].each do |m|
        @q.send(m).must_equal []
        @q.send(m).frozen?.must_equal true
      end
      @q.archive_path.must_match %r{\A/tmp/haus-\d+-[a-z]+\.tar\.gz\z}
      @q.archive_path.frozen?.must_equal true
    end
  end

  describe :add_link do
    it 'should noop and return nil when src does not exist' do
      @q.add_link('/magic/pony/with/sparkles', "#{$user.dir}/sparkles").must_be_nil
      @q.links.empty?.must_equal true
    end

    it 'should noop and return nil when dst points to src' do
      begin
        src = $user.hausfiles.first
        dst = "#{$user.dir}/.#{File.basename src}"
        FileUtils.ln_s src, dst
        @q.add_link(src, dst).must_be_nil
        @q.links.empty?.must_equal true
      ensure
        FileUtils.rm_f dst
      end
    end

    it 'should push and refreeze @links when src does exist and dst does not point to src' do
      args = %W[#{$user.hausfiles.first} #{$user.dir}/.dest]
      res = @q.add_link *args
      res.must_equal [args]
      res.frozen?.must_equal true
      @q.links.must_equal [args]
      @q.links.frozen?.must_equal true
    end

    it 'should raise an error when a job for dst already exists' do
      @q.add_link *%W[#{$user.hausfiles.first} #{$user.dir}/.dest]
      assert_raises Haus::Queue::MultipleJobError do
        @q.add_link *%W[#{$user.hausfiles.first} #{$user.dir}/.dest]
      end
    end
  end

  describe :add_copy do
    it 'should noop and return nil when src does not exist' do
      @q.add_copy('/magic/pony/with/sparkles', "#{$user.dir}/sparkles").must_be_nil
      @q.copies.empty?.must_equal true
    end

    it 'should noop and return nil when src and dst equal' do
      begin
        src = $user.hausfiles.first
        dst = "#{$user.dir}/.#{File.basename src}"
        FileUtils.cp src, dst
        @q.add_copy(src, dst).must_be_nil
        @q.copies.empty?.must_equal true
      ensure
        FileUtils.rm_f dst
      end
    end

    it 'should push and refreeze @copies when src exists and dst does not equal src' do
      args = %W[#{$user.hausfiles.first} #{$user.dir}/.dest]
      res = @q.add_copy *args
      res.must_equal [args]
      res.frozen?.must_equal true
      @q.copies.must_equal [args]
      @q.copies.frozen?.must_equal true
    end

    it 'should raise an error when a job for dst already exists' do
      @q.add_copy *%W[#{$user.hausfiles.first} #{$user.dir}/.dest]
      assert_raises Haus::Queue::MultipleJobError do
        @q.add_copy *%W[#{$user.hausfiles.first} #{$user.dir}/.dest]
      end
    end
  end

  describe :add_deletion do
    it 'should noop and return nil when dst does not exist' do
      @q.add_deletion('/magical/pony/with/sparkle/action').must_be_nil
      @q.deletions.empty?.must_equal true
    end

    it 'should push and refreeze @deletions when dst exists' do
      res = @q.add_deletion($user.hausfiles.first)
      res.must_equal [$user.hausfiles.first]
      res.frozen?.must_equal true
      @q.deletions.must_equal [$user.hausfiles.first]
      @q.deletions.frozen?.must_equal true
    end

    it 'should raise an error when a job for dst already exists' do
      @q.add_deletion $user.hausfiles.first
      assert_raises Haus::Queue::MultipleJobError do
        @q.add_deletion $user.hausfiles.first
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
      @q.add_modification($user.hausfiles.first) { |f| touch f }
      assert_raises Haus::Queue::MultipleJobError do
        @q.add_modification($user.hausfiles.first) { |f| touch f }
      end
    end
  end

  describe :targets do
  end

  describe :tty_confirm? do
  end
end

