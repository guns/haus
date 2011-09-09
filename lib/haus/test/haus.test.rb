# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

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
      capture_fork_io { Haus.new.options.parse '--version' }.first.chomp.must_equal Haus::VERSION
      capture_fork_io { Haus.new.options.parse '--help' }.first.chomp.must_equal Haus.new.help
    end
  end

  describe :run do
    it 'must return help if a proper task is not passed' do
      help = Haus.new.help
      capture_fork_io { Haus.new.run }.first.chomp.must_equal help
      capture_fork_io { Haus.new(%w[foo]).run }.first.chomp.must_equal help
    end

    it 'must parse options in order' do
      help = Haus.new.help
      capture_fork_io { Haus.new(%w[--help link]).run }.first.chomp.must_equal help
      capture_fork_io { Haus.new(%w[link --help]).run }.first.chomp.wont_equal help
    end

    it 'must exit(0) if true and exit(1) otherwise' do
      capture_fork_io { print Haus.new(%w[nooptrue]).run.inspect }.first.must_equal 'true'
      capture_fork_io { print Haus.new(%w[noopnil]).run.inspect }.first.must_equal ''
      $?.exitstatus.must_equal 1
    end

    it 'must rescue StandardError exceptions and abort' do
      capture_fork_io { Haus.new(%w[noopraise]).run }.first.must_match /NoopRaise\n\z/
      $?.exitstatus.must_equal 1
    end

    it 'must print the error backtrace if options.debug' do
      capture_fork_io do
        h = Haus.new(%w[noopraise])
        h.options.debug = true
        h.run
      end.first.split("\n").size.wont_equal 1 # 1.8.6 doesn't have String#lines
    end
  end
end
