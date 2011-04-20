# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and RUBY_VERSION > '1.8.6'
require 'minitest/autorun'
require 'haus/task'

class Haus::Pony < Haus::Task; end

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
        Haus::Pony.command.must_equal 'pony'
      end
    end

    describe :inherited do
      it 'should create a Task::list entry for the new subclass' do
        class Haus::HausPony < Haus::Task; end
        Haus::Task.list['hauspony'].must_be_kind_of Hash
        Haus::Task.list['hauspony'][:class].must_equal Haus::HausPony
        Haus::Task.list['hauspony'][:desc].must_equal ''
        Haus::Task.list['hauspony'][:banner].must_equal ''
      end
    end

    describe :desc do
      it 'should set the one line description for the subclass' do
        Haus::Pony.desc 'A very nice pony'
        Haus::Task.list['pony'][:desc].must_equal 'A very nice pony'
      end
    end

    describe :banner do
      it 'should set the help output header' do
        Haus::Pony.banner "This is a very nice pony indeed.\nMagic powers."
        Haus::Task.list['pony'][:banner].must_equal "This is a very nice pony indeed.\nMagic powers."
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
      Haus::Pony.method(:initialize).arity.must_equal -1
      Haus::Pony.new(%w[-f noprocrast]).instance_variable_get(:@args).must_equal %w[-f noprocrast]
    end
  end
end
