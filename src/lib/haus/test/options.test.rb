# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and RUBY_VERSION > '1.8.6'
require 'minitest/autorun'
require 'haus/options'

describe Haus::Options do
  it 'should be a subclass of OptionParser' do
    Haus::Options.new.must_be_kind_of OptionParser
  end

  describe :tap do
    it 'should respond to #tap, which should behave like Ruby 1.9 Object#tap' do
      Haus::Options.new.must_respond_to :tap
      hopts = Haus::Options.new
      hopts.tap { |opt| opt.must_equal hopts }.must_equal hopts
    end
  end

  describe :method_missing do
    it 'should otherwise act like an OpenStruct object' do
      opt = Haus::Options.new
      opt.force = true
      opt.force.must_equal true
      opt.horse = 'of course'
      opt.horse.must_equal 'of course'
      opt.norse = 'Viking'
      opt.norse.must_equal 'Viking'
    end
  end

  describe :path do
    it 'should always return a Pathname object' do
      opt = Haus::Options.new
      opt.path.must_be_kind_of Pathname
      opt.path.must_equal Pathname.new(File.expand_path '../../../../..', __FILE__)
    end
  end

  describe :path= do
    it 'should always set :@path as a Pathname object' do
      opt = Haus::Options.new
      opt.path = '/opt/haus'
      opt.path.must_equal Pathname.new('/opt/haus')
    end
  end
end
