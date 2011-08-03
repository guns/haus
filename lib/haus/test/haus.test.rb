# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and [].respond_to? :cycle
require 'minitest/autorun'
require 'haus'
require 'haus/test/helper/minitest'
require 'haus/test/helper/noop_tasks'

describe Haus do
  describe :initialize do
    it 'should accept an optional arguments array' do
      Haus.method(:initialize).arity.must_equal -1
      Haus.new(%w[-h foo]).instance_variable_get(:@args).must_equal %w[-h foo]
    end
  end

  describe :help do
    it 'should return a usage string' do
      help = Haus.new.help
      help.must_be_kind_of String
      help.must_match /^Usage/
    end
  end

  describe :options do
    it 'should return a Haus::Options object' do
      Haus.new.options.must_be_kind_of Haus::Options
    end

    it 'should respond to --version and --help' do
      capture_fork_io { Haus.new.options.parse '--version' }.join.chomp.must_equal Haus::VERSION
      capture_fork_io { Haus.new.options.parse '--help' }.join.chomp.must_equal Haus.new.help
    end

    it 'should set options.path via --path' do
      h = Haus.new %w[--path /opt/testhaus noop]
      h.run
      h.options.path.must_equal '/opt/testhaus'
    end
  end

  describe :run do
    it 'should return help if a proper task is not passed' do
      help = Haus.new.help
      capture_fork_io { Haus.new.run }.join.chomp.must_equal help
      capture_fork_io { Haus.new(%w[foo]).run }.join.chomp.must_equal help
    end

    it 'should pass options.path to the task' do
      t1 = Haus.new(%w[noopself]).run
      t1.options.path.must_equal Haus::Options.new.path
      t2 = Haus.new(%w[--path /opt/testhaus noopself]).run
      t2.options.path.must_equal '/opt/testhaus'
    end

    it 'should parse options in order' do
      help = Haus.new.help
      capture_fork_io { Haus.new(%w[--help link]).run }.join.chomp.must_equal help
      capture_fork_io { Haus.new(%w[link --help]).run }.join.chomp.wont_equal help
    end

    it 'should return a boolean value' do
      capture_fork_io { print Haus.new(%w[nooptrue]).run.to_s }.join.must_equal 'true'
      capture_fork_io { print Haus.new(%w[noopfalse]).run.to_s }.join.must_equal 'false'
    end
  end
end
