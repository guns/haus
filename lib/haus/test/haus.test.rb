# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and [].respond_to? :cycle
require 'minitest/autorun'
require 'haus'
require 'haus/test/helper/minitest'
require 'haus/test/helper/noop_tasks'

class HausSpec < MiniTest::Spec
  describe :initialize do
    it 'must accept an optional arguments array' do
      Haus.method(:initialize).arity.must_equal -1
      Haus.new(%w[-h foo]).instance_variable_get(:@args).must_equal %w[-h foo]
    end
  end

  describe :help do
    it 'must return a usage string' do
      help = Haus.new.help
      help.must_be_kind_of String
      help.must_match /^Usage/
    end
  end

  describe :options do
    it 'must return a Haus::Options object' do
      Haus.new.options.must_be_kind_of Haus::Options
    end

    it 'must respond to --version and --help' do
      capture_fork_io { Haus.new.options.parse '--version' }.join.chomp.must_equal Haus::VERSION
      capture_fork_io { Haus.new.options.parse '--help' }.join.chomp.must_equal Haus.new.help
    end

    it 'must set options.path via --path' do
      h = Haus.new %w[--path /opt/testhaus noop]
      h.run
      h.options.path.must_equal '/opt/testhaus'
    end
  end

  describe :run do
    it 'must return help if a proper task is not passed' do
      help = Haus.new.help
      capture_fork_io { Haus.new.run }.join.chomp.must_equal help
      capture_fork_io { Haus.new(%w[foo]).run }.join.chomp.must_equal help
    end

    it 'must pass options.path to the task' do
      h1 = Haus.new %w[noop]
      h1.run
      h1.options.path.must_equal Haus::Options.new.path
      h2 = Haus.new %w[--path /opt/testhaus noop]
      h2.run
      h2.options.path.must_equal '/opt/testhaus'
    end

    it 'must parse options in order' do
      help = Haus.new.help
      capture_fork_io { Haus.new(%w[--help link]).run }.join.chomp.must_equal help
      capture_fork_io { Haus.new(%w[link --help]).run }.join.chomp.wont_equal help
    end

    it 'must return true or nil' do
      capture_fork_io { print Haus.new(%w[nooptrue]).run.inspect }.join.must_equal 'true'
      capture_fork_io { print Haus.new(%w[noopnil]).run.inspect }.join.must_equal 'nil'
    end
  end
end
