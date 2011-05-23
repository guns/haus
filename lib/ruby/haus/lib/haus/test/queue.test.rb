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
    it 'should initialize the attr_readers' do
      @q.links.must_equal []
      @q.copies.must_equal []
      @q.modifications.must_equal []
      @q.deletions.must_equal []
      @q.archive_path.must_match %r{\A/tmp/haus-\d+-[a-z]+\.tar\.gz\z}
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

    it 'should push and return @links when src does exist and dst does not point to src' do
      args = %W[/etc/passwd #{$user.dir}/.passwd]
      @q.add_link(*args).must_equal [args]
      @q.links.must_equal [args]
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

    it 'should push and return @copies when src exists and dst does not equal src' do
      args = %W[/etc/passwd #{$user.dir}/.passwd]
      @q.add_link(*args).must_equal [args]
      @q.links.must_equal [args]
    end
  end

  describe :add_deletion do
    it 'should noop and return nil when dst does not exist' do
      @q.add_deletion('/magical/pony/with/sparkle/action').must_be_nil
      @q.deletions.empty?.must_equal true
    end

    it 'should push and return @deletions when dst exists' do
      @q.add_deletion($user.hausfiles.first).must_equal [$user.hausfiles.first]
      @q.deletions.must_equal [$user.hausfiles.first]
    end
  end

  describe :add_modification do
  end

  describe :targets do
  end

  describe :tty_confirm? do
  end
end
