# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and RUBY_VERSION > '1.8.6'
require 'minitest/autorun'
require 'haus'
require 'haus/test/helper'

include HausHelper

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
  end

  describe :run do
    it 'should return help if a proper task is not passed' do
      help = Haus.new.help
      capture_fork_io { Haus.new.run }.join.chomp.must_equal help
      capture_fork_io { Haus.new(%w[foo]).run }.join.chomp.must_equal help
    end

    # TODO: high level tests for the command could go here
  end
end
