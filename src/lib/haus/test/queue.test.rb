# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and RUBY_VERSION > '1.8.6'
require 'minitest/autorun'
require 'haus/queue'

describe Haus::Queue do
  it 'should have included FileUtils' do
    Haus::Queue.included_modules.must_include FileUtils
  end

  describe :initialize do
    it 'should initialize the attr_readers' do
      q = Haus::Queue.new
      q.links.must_equal []
      q.copies.must_equal []
      q.modifications.must_equal []
      q.deletions.must_equal []
    end
  end

  describe :add_link do
  end

  describe :add_copy do
  end

  describe :add_modification do
  end

  describe :add_deletion do
  end

  describe :targets do
  end

  describe :tty_confirm? do
  end

  describe :archive_path do
  end
end
