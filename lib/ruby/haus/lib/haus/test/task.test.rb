# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and [].respond_to? :cycle
require 'minitest/autorun'
require 'haus/task'
require 'haus/test/helper'

describe Haus::Task do
  describe :self do
    describe :list do
      # http://stackoverflow.com/questions/3434884/accessing-ruby-class-variables-with-class-eval-and-instance-eval
      it 'should return the metaclass @@list variable' do
        Haus::Task.list.must_be_kind_of Hash
      end
    end

    describe :command do
      it "should return the current subclass's command name" do
        Haus::Noop.command.must_equal 'noop'
      end
    end

    describe :inherited do
      it 'should create a Task::list entry for the new subclass' do
        class Haus::Noop2 < Haus::Task; end
        Haus::Task.list['noop2'].must_be_kind_of Hash
        Haus::Task.list['noop2'][:class].must_equal Haus::Noop2
        Haus::Task.list['noop2'][:desc].must_equal ''
        Haus::Task.list['noop2'][:banner].must_equal ''
      end
    end

    describe :desc do
      it 'should set the one line description for the subclass' do
        msg = 'This class does nothing.'
        Haus::Noop.desc msg
        Haus::Task.list['noop'][:desc].must_equal msg
      end
    end

    describe :banner do
      it 'should set the help output header' do
        msg = 'This class does nothing; its purpose is to ease automated testing.'
        Haus::Noop.banner msg
        Haus::Task.list['noop'][:banner].must_equal msg
      end
    end

    describe :summary do
      it 'should return a summary of all subclasses of Haus::Task' do
        buf = Haus::Task.summary
        Haus::Task.list.keys.each do |cmd|
          buf.must_match Regexp.new('^\s+' + cmd)
        end
      end
    end
  end

  describe :initialize do
    it 'should accept an optional arguments Array' do
      Haus::Noop.method(:initialize).arity.must_equal -1
      Haus::Noop.new(%w[-f noprocrast]).instance_variable_get(:@args).must_equal %w[-f noprocrast]
    end
  end

  describe :queue do
    it 'should always return a Queue instance' do
      h = Haus::Noop.new
      h.queue.must_be_kind_of Haus::Queue
    end
  end

  describe :meta do
    it 'should access the Task::list entry for the current subclass' do
      h = Haus::Noop.new
      h.meta.must_be_kind_of Hash
      h.meta[:class].must_equal Haus::Noop
      h.meta[:desc].must_equal Haus::Task.list['noop'][:desc]
      h.meta[:banner].must_equal Haus::Task.list['noop'][:banner]
    end
  end

  describe :options do
    it 'should be an instance of Haus::Options' do
      Haus::Noop.new.options.must_be_kind_of Haus::Options
    end

    it 'should have its own help message' do
      Haus::Noop.new.options.to_s.must_match /^Usage:.+ noop/
    end

    it 'should prove the default options for all Task subclasses' do
      runoptions = lambda { |args| h = Haus::Noop.new args; h.run; h.options }
      runoptions.call(%w[--force]).force.must_equal true
      runoptions.call(%w[--noop]).noop.must_equal true
      runoptions.call(%w[--quiet]).quiet.must_equal true
      capture_fork_io { Haus::Noop.new(%w[--help]).run }.join.must_equal Haus::Noop.new.options.to_s
    end
  end

  describe :call do
    it 'should accept an optional argument' do
      m = Haus::Task.new.method :call
      m.arity.must_equal -1
    end
  end

  describe :run do
    it 'should set options.cli' do
      h = Haus::Noop.new
      h.options.cli.must_equal nil
      h.run
      h.options.cli.must_equal true
    end

    it 'should call Haus::Task#call' do
      h = Haus::Noop.new
      h.instance_eval do
        def call args = []
          @call_method_called = true
        end
      end
      h.run
      h.instance_variable_get(:@call_method_called).must_equal true
    end

    it 'should pass Haus::Task#call the remaining ARGV after options parsing' do
      h = Haus::Noop.new %w[--force --quiet magic pony]
      h.instance_eval do
        def call args = []
          @call_args = args
        end
      end
      h.run
      h.instance_variable_get(:@call_args).must_equal %w[magic pony]
    end
  end
end
